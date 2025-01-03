//
//  PopoverView.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import SwiftUI

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
