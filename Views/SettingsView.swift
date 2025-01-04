//
//  SettingsView.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var monitor: NetworkMonitor // Add this
    @State private var showingResetConfirmation = false // Add this
    
    var body: some View {
        Form {
            Picker("Menu Bar Display", selection: $settings.displayMode) {
                Text("Show Total Usage")
                    .tag(AppSettings.DisplayMode.totalInMenuBar)
                Text("Show Network Speeds")
                    .tag(AppSettings.DisplayMode.speedInMenuBar)
            }
            .pickerStyle(.inline)
            
            Text("Choose what information to display in the menu bar.")
                .font(.caption)
                .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("Reset Statistics", systemImage: "arrow.counterclockwise")
                }
                .padding(.top)
        }
        .padding()
        .frame(width: 420)
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
