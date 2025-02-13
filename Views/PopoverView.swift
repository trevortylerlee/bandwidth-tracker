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
    @State private var showingQuitConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
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
            
            HStack {
                Text("Session duration:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formattedTrackingDuration)
                    .font(.caption)
                Spacer()
                
                SettingsLink {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                
                Button {
                    showingQuitConfirmation = true
                } label: {
                    Image(systemName: "power")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .help("Quit Application")
            }
        }
        .frame(width: 250)
        .padding()
        .alert("Quit Application", isPresented: $showingQuitConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Quit", role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    }
                } message: {
                    Text("Are you sure you want to quit Bandwidth Tracker?")
                }
    }
    
    var formattedTrackingDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: monitor.stats.sessionDuration) ?? ""
    }
}
