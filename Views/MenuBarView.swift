//
//  MenuBarView.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var monitor: NetworkMonitor
    
    var body: some View {
        HStack {
            Text("↓ \(ByteCountFormatting.string(fromByteCount: monitor.stats.totalDownloaded)) ⋅ ↑ \(ByteCountFormatting.string(fromByteCount: monitor.stats.totalUploaded))")
        }
    }
}
