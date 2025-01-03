//
//  Bandwidth_TrackerApp.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2024-12-30.
//

import SwiftUI
import Network
import Foundation
import SystemConfiguration
import AppKit
import Charts

// MARK: - Formatting Helper
struct ByteCountFormatting {
    static func string(fromByteCount bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
    
    static func string(fromBytesPerSecond bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes)) + "/s"
    }
}

// MARK: - Models
struct NetworkStats: Codable {
    var uploadSpeed: Double = 0
    var downloadSpeed: Double = 0
    var totalUploaded: Int64 = 0
    var totalDownloaded: Int64 = 0
    var startTime: Date
    var dataPoints: [NetworkDataPoint] = []
    var lastKnownUploadBytes: Int64 = 0
    var lastKnownDownloadBytes: Int64 = 0
    
    init() {
        startTime = Date()
        totalUploaded = 0
        totalDownloaded = 0
        lastKnownUploadBytes = 0
        lastKnownDownloadBytes = 0
    }
}

struct NetworkDataPoint: Codable, Identifiable {
    var id: UUID
    let timestamp: Date
    let uploadBytes: Int64
    let downloadBytes: Int64
    
    init(id: UUID = UUID(), timestamp: Date, uploadBytes: Int64, downloadBytes: Int64) {
        self.id = id
        self.timestamp = timestamp
        self.uploadBytes = uploadBytes
        self.downloadBytes = downloadBytes
    }
}

// MARK: - Network Monitor Class
class NetworkMonitor: ObservableObject {
    @Published private(set) var stats: NetworkStats
    
    private var previousUploadBytes: Int64 = 0
    private var previousDownloadBytes: Int64 = 0
    private var lastUpdateTime = Date()
    private let statsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("networkStats.json")
    
    init() {
        // Initialize with default stats
        self.stats = NetworkStats()
        
        // Try to load saved stats
        if let loadedStats = loadStats() {
            self.stats = loadedStats
            self.previousUploadBytes = loadedStats.lastKnownUploadBytes
            self.previousDownloadBytes = loadedStats.lastKnownDownloadBytes
        }
        
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.updateNetworkStats()
        }
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
        stats = NetworkStats()
        previousUploadBytes = 0
        previousDownloadBytes = 0
        saveStats()
    }
}
// MARK: - Views
struct MenuBarView: View {
    @ObservedObject var monitor: NetworkMonitor
    
    var body: some View {
        HStack {
            Text("↓ \(ByteCountFormatting.string(fromByteCount: monitor.stats.totalDownloaded)) ⋅ ↑ \(ByteCountFormatting.string(fromByteCount: monitor.stats.totalUploaded))")
        }
    }
}

struct NetworkUsageGraph: View {
    let dataPoints: [NetworkDataPoint]
    
    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Download", point.downloadBytes),
                    series: .value("Type", "Download")
                )
                .foregroundStyle(.blue)
                
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Upload", point.uploadBytes),
                    series: .value("Type", "Upload")
                )
                .foregroundStyle(.orange)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let bytes = value.as(Int64.self) {
                        Text(ByteCountFormatting.string(fromByteCount: bytes))
                    }
                }
            }
        }
        .frame(height: 200)
        .padding()
    }
}

struct PopoverView: View {
    @ObservedObject var monitor: NetworkMonitor
    @State private var showingResetConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Speeds Section
            Group {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                        Text("Download:")
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatting.string(fromBytesPerSecond: monitor.stats.downloadSpeed))
                    }
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.orange)
                        Text("Upload:")
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatting.string(fromBytesPerSecond: monitor.stats.uploadSpeed))
                    }
                }
            }
            
            // Graph Section
            NetworkUsageGraph(dataPoints: monitor.stats.dataPoints)
            
            HStack {
                // Time tracking
                            Text("Session time: \(formattedTrackingDuration)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                  
                            Spacer()
                            // Reset Button
                            Button("Reset Statistics") {
                                showingResetConfirmation = true
                            }
                            .alert("Reset Statistics", isPresented: $showingResetConfirmation) {
                                Button("Cancel", role: .cancel) { }
                                Button("Reset", role: .destructive) {
                                    monitor.resetStats()
                                }
                            } message: {
                                Text("Are you sure you want to reset all network statistics? This cannot be undone.")
                            }
            }
        }
        .frame(width: 400)
        .padding()
    }
    
    var formattedTrackingDuration: String {
        let duration = Date().timeIntervalSince(monitor.stats.startTime)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

@main
struct NetworkMonitorApp: App {
    @StateObject private var monitor = NetworkMonitor()
    
    var body: some Scene {
        MenuBarExtra {
            PopoverView(monitor: monitor)
        } label: {
            MenuBarView(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}
