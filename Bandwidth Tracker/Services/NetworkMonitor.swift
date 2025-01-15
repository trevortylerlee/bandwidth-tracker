//
//  NetworkMonitor.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import Network
import Foundation
import SystemConfiguration
import AppKit

class NetworkMonitor: ObservableObject {
    @Published private(set) var stats: NetworkStats
    
    private var combinedTimer: DispatchSourceTimer?
    private var needsSaving = false
    private var lastSaveTime = Date()
    private let statsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("networkStats.json")
    private let saveInterval: TimeInterval = 60
    private let notificationCenter = NotificationCenter.default
    
    private var lastStatsUpdateTime = Date()
    private var previousUploadBytes: Int64 = 0
    private var previousDownloadBytes: Int64 = 0
    private var lastUpdateTime = Date()
    
    init() {
        self.stats = NetworkStats()
        
        if let loadedStats = loadStats() {
            self.stats = loadedStats
            self.previousUploadBytes = loadedStats.lastKnownUploadBytes
            self.previousDownloadBytes = loadedStats.lastKnownDownloadBytes
        }
        
        setupNotifications()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
        notificationCenter.removeObserver(self)
        if needsSaving {
            saveStats()
        }
    }
    
    private func setupNotifications() {
        notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
    }
    
    @objc private func handleSleep() {
        saveStats()
    }
    
    @objc private func handleWake() {
        startMonitoring()
    }
    
    private func checkAndSaveIfNeeded() {
        let now = Date()
        if needsSaving && now.timeIntervalSince(lastSaveTime) >= saveInterval {
            saveStats()
            lastSaveTime = now
            needsSaving = false
        }
    }
    
    private func startMonitoring() {
        stats.isMonitoring = true
        
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now(), repeating: .milliseconds(1000))
        
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if self.stats.isMonitoring {
                    self.stats.sessionDuration += 1
                    self.needsSaving = true
                }
            }
            
            let now = Date()
            if now.timeIntervalSince(self.lastStatsUpdateTime) >= 5.0 {
                self.updateNetworkStats()
                self.lastStatsUpdateTime = now
            }
            
            self.checkAndSaveIfNeeded()
        }
        
        combinedTimer = timer
        timer.resume()
    }
    
    private func stopMonitoring() {
        stats.isMonitoring = false
        combinedTimer?.cancel()
        combinedTimer = nil
    }
    
    private func updateNetworkStats() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return }
        defer { freeifaddrs(ifaddr) }
        
        var currentUploadBytes: Int64 = 0
        var currentDownloadBytes: Int64 = 0
        
        var ptr = ifaddr
        while ptr != nil {
            let interface = ptr!.pointee
            let name = String(cString: interface.ifa_name)
            
            if name == "en0" || name == "en1" {
                if let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) {
                    currentUploadBytes += Int64(max(0, data.pointee.ifi_obytes))
                    currentDownloadBytes += Int64(max(0, data.pointee.ifi_ibytes))
                }
            }
            ptr = interface.ifa_next
        }
        
        let timeInterval = Date().timeIntervalSince(lastUpdateTime)
        
        if previousUploadBytes > 0 && previousDownloadBytes > 0 &&
            currentUploadBytes >= previousUploadBytes &&
            currentDownloadBytes >= previousDownloadBytes {
            
            let uploadDiff = currentUploadBytes - previousUploadBytes
            let downloadDiff = currentDownloadBytes - previousDownloadBytes
            
            DispatchQueue.main.async {
                self.stats.uploadSpeed = Double(uploadDiff) / timeInterval
                self.stats.downloadSpeed = Double(downloadDiff) / timeInterval
                
                self.stats.totalUploaded += uploadDiff
                self.stats.totalDownloaded += downloadDiff
                
                self.stats.lastKnownUploadBytes = currentUploadBytes
                self.stats.lastKnownDownloadBytes = currentDownloadBytes
                
                self.needsSaving = true
            }
        }
        
        previousUploadBytes = currentUploadBytes
        previousDownloadBytes = currentDownloadBytes
        lastUpdateTime = Date()
    }
    
    private func saveStats() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(stats)
            try data.write(to: statsURL, options: .atomicWrite)
        } catch {
            print("Failed to save stats: \(error)")
        }
    }
    
    private func loadStats() -> NetworkStats? {
        do {
            let data = try Data(contentsOf: statsURL)
            let decoder = JSONDecoder()
            return try decoder.decode(NetworkStats.self, from: data)
        } catch {
            print("Failed to load stats: \(error)")
            return nil
        }
    }
    
    func resetStats() {
        stopMonitoring()
        stats = NetworkStats()
        previousUploadBytes = 0
        previousDownloadBytes = 0
        saveStats()
        lastSaveTime = Date()
        needsSaving = false
        startMonitoring()
    }
}
