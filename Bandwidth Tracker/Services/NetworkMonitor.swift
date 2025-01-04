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
    
    private var previousUploadBytes: Int64 = 0
    private var previousDownloadBytes: Int64 = 0
    private var lastUpdateTime = Date()
    private var sessionTimer: Timer?
    private var statsTimer: Timer?
    private var needsSaving = false
    private var lastSaveTime = Date()
    private let statsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("networkStats.json")
    private let saveInterval: TimeInterval = 60
    private let notificationCenter = NotificationCenter.default
    
    init() {
        self.stats = NetworkStats()
        
        if let loadedStats = loadStats() {
            self.stats = loadedStats
            self.previousUploadBytes = loadedStats.lastKnownUploadBytes
            self.previousDownloadBytes = loadedStats.lastKnownDownloadBytes
            
            // Handle potential sleep gap on app launch
            handleTimeGap(from: loadedStats.lastActiveTimestamp)
        }
        
        setupNotifications()
        startMonitoring()
    }
    
    deinit {
        sessionTimer?.invalidate()
        statsTimer?.invalidate()
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
        // Save the current state before sleep
        stats.lastActiveTimestamp = Date()
        saveStats()
    }
    
    @objc private func handleWake() {
        // Handle the time gap since last active timestamp
        handleTimeGap(from: stats.lastActiveTimestamp)
        startMonitoring()
    }
    
    private func handleTimeGap(from lastTimestamp: Date) {
        let now = Date()
        let gap = now.timeIntervalSince(lastTimestamp)
        
        // If there's a significant gap (more than 2 minutes)
        if gap > 120 {
            // Create a "gap" data point using the last known values
            if let lastPoint = stats.dataPoints.last {
                let gapPoint = NetworkDataPoint(
                    timestamp: lastTimestamp.addingTimeInterval(60), // 1 minute after last known point
                    uploadBytes: lastPoint.uploadBytes,
                    downloadBytes: lastPoint.downloadBytes
                )
                stats.dataPoints.append(gapPoint)
                
                // Create a new point at current time with same values
                let currentPoint = NetworkDataPoint(
                    timestamp: now,
                    uploadBytes: lastPoint.uploadBytes,
                    downloadBytes: lastPoint.downloadBytes
                )
                stats.dataPoints.append(currentPoint)
            }
        }
        
        stats.lastActiveTimestamp = now
        needsSaving = true
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
        
        // Network stats update timer - reduced frequency
        statsTimer?.invalidate()
        statsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateNetworkStats()
        }
        RunLoop.current.add(statsTimer!, forMode: .common)
        
        // Session duration timer
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.stats.isMonitoring {
                self.stats.sessionDuration += 1
                self.needsSaving = true
                self.checkAndSaveIfNeeded()
            }
        }
        RunLoop.current.add(sessionTimer!, forMode: .common)
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
            
            stats.uploadSpeed = Double(uploadDiff) / timeInterval
            stats.downloadSpeed = Double(downloadDiff) / timeInterval
            
            stats.totalUploaded += uploadDiff
            stats.totalDownloaded += downloadDiff
            
            stats.lastKnownUploadBytes = currentUploadBytes
            stats.lastKnownDownloadBytes = currentDownloadBytes
            
            // Update last active timestamp
            stats.lastActiveTimestamp = Date()
            
            // Only add data points every minute
            if stats.dataPoints.isEmpty || Date().timeIntervalSince(stats.dataPoints.last?.timestamp ?? Date.distantPast) >= 60 {
                let dataPoint = NetworkDataPoint(
                    timestamp: Date(),
                    uploadBytes: stats.totalUploaded,
                    downloadBytes: stats.totalDownloaded
                )
                stats.dataPoints.append(dataPoint)
                
                // Limit the number of data points to prevent memory growth
                if stats.dataPoints.count > 1440 { // 24 hours worth of minute-by-minute data
                    stats.dataPoints.removeFirst(stats.dataPoints.count - 1440)
                }
                
                needsSaving = true
            }
            
            checkAndSaveIfNeeded()
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
        // Stop current monitoring
        sessionTimer?.invalidate()
        statsTimer?.invalidate()
        
        // Reset all stats
        stats = NetworkStats()
        previousUploadBytes = 0
        previousDownloadBytes = 0
        
        // Force an immediate save
        saveStats()
        
        // Reset timers
        lastSaveTime = Date()
        needsSaving = false
        
        // Restart monitoring
        startMonitoring()
    }
}
