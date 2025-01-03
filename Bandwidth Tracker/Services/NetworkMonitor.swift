//
//  NetworkMonitor.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import Network
import Foundation
import SystemConfiguration

class NetworkMonitor: ObservableObject {
    @Published private(set) var stats: NetworkStats
    
    private var previousUploadBytes: Int64 = 0
        private var previousDownloadBytes: Int64 = 0
        private var lastUpdateTime = Date()
        private var sessionTimer: Timer?
        private let statsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("networkStats.json")
    
    init() {
            self.stats = NetworkStats()
            
            if let loadedStats = loadStats() {
                self.stats = loadedStats
                self.previousUploadBytes = loadedStats.lastKnownUploadBytes
                self.previousDownloadBytes = loadedStats.lastKnownDownloadBytes
            }
            
            startMonitoring()
        }
    
    deinit {
        sessionTimer?.invalidate()
    }
    
    private func startMonitoring() {
            stats.isMonitoring = true
            
            // Network stats update timer
            Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
                self?.updateNetworkStats()
            }
            
            // Session duration timer
            sessionTimer?.invalidate() // Ensure any existing timer is invalidated
            sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.stats.isMonitoring {
                    self.stats.sessionDuration += 1
                    self.saveStats() // Save regularly to persist session duration
                }
            }
            
            // Make sure the timer stays active even when the popover is closed
            RunLoop.current.add(sessionTimer!, forMode: .common)
        }
    
    func pauseMonitoring() {
        stats.isMonitoring = false
        saveStats()
    }
    
    func resumeMonitoring() {
        stats.isMonitoring = true
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
        
        // Only update if we have valid previous values and the current values are greater
        if previousUploadBytes > 0 && previousDownloadBytes > 0 &&
           currentUploadBytes >= previousUploadBytes &&
           currentDownloadBytes >= previousDownloadBytes {
            
            let uploadDiff = currentUploadBytes - previousUploadBytes
            let downloadDiff = currentDownloadBytes - previousDownloadBytes
            
            stats.uploadSpeed = Double(uploadDiff) / timeInterval
            stats.downloadSpeed = Double(downloadDiff) / timeInterval
            
            stats.totalUploaded += uploadDiff
            stats.totalDownloaded += downloadDiff
            
            // Store the current values for persistence
            stats.lastKnownUploadBytes = currentUploadBytes
            stats.lastKnownDownloadBytes = currentDownloadBytes
            
            // Add data point every minute
            if stats.dataPoints.isEmpty || Date().timeIntervalSince(stats.dataPoints.last?.timestamp ?? Date.distantPast) >= 60 {
                let dataPoint = NetworkDataPoint(
                    timestamp: Date(),
                    uploadBytes: stats.totalUploaded,
                    downloadBytes: stats.totalDownloaded
                )
                stats.dataPoints.append(dataPoint)
            }
            
            saveStats()
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
        sessionTimer?.invalidate()
        stats = NetworkStats()
        previousUploadBytes = 0
        previousDownloadBytes = 0
        saveStats()
        startMonitoring()
    }
}
