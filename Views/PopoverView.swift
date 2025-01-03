//
//  PopoverView.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import SwiftUI

struct PopoverView: View {
    @ObservedObject var monitor: NetworkMonitor
    @ObservedObject var settings: AppSettings
    @State private var showingResetConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                        Text(settings.displayMode.popoverLabels.download)
                            .foregroundStyle(.secondary)
                        switch settings.displayMode {
                        case .speedInMenuBar:
                            Text(ByteCountFormatting.string(fromByteCount: monitor.stats.totalDownloaded))
                        case .totalInMenuBar:
                            Text(ByteCountFormatting.string(fromBytesPerSecond: monitor.stats.downloadSpeed))
                        }
                    }
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.orange)
                        Text(settings.displayMode.popoverLabels.upload)
                            .foregroundStyle(.secondary)
                        switch settings.displayMode {
                        case .speedInMenuBar:
                            Text(ByteCountFormatting.string(fromByteCount: monitor.stats.totalUploaded))
                        case .totalInMenuBar:
                            Text(ByteCountFormatting.string(fromBytesPerSecond: monitor.stats.uploadSpeed))
                        }
                    }
                }
            }
            
            NetworkUsageGraph(dataPoints: monitor.stats.dataPoints)
            
            HStack {
                            Text("Session duration:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formattedTrackingDuration)
                                .font(.caption)
                            Spacer()
                            
                            HStack(spacing: 8) {
                                SettingsLink {
                                    Image(systemName: "gear")
                                }
                                .buttonStyle(.borderless)
                                
                                Button {
                                    showingResetConfirmation = true
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                }
                                .buttonStyle(.borderless)
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
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: monitor.stats.sessionDuration) ?? ""
    }
}
