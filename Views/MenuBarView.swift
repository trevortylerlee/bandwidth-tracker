//
//  MenuBarView.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var monitor: NetworkMonitor
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        HStack {
            switch settings.displayMode {
            case .speedInMenuBar:
                Text("↓ \(ByteCountFormatting.string(fromBytesPerSecond: monitor.stats.downloadSpeed)) ⋅ ↑ \(ByteCountFormatting.string(fromBytesPerSecond: monitor.stats.uploadSpeed))")
            case .totalInMenuBar:
                Text("↓ \(ByteCountFormatting.string(fromByteCount: monitor.stats.totalDownloaded)) ⋅ ↑ \(ByteCountFormatting.string(fromByteCount: monitor.stats.totalUploaded))")
            }
        }
    }
}
