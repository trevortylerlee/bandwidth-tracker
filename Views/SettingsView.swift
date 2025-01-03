//
//  SettingsView.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Form {
            Picker("Menu Bar Display", selection: $settings.displayMode) {
                Text("Show Network Speeds")
                    .tag(AppSettings.DisplayMode.speedInMenuBar)
                Text("Show Total Usage")
                    .tag(AppSettings.DisplayMode.totalInMenuBar)
            }
            .pickerStyle(.inline)
            
            Text("Choose what information to display in the menu bar.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 420)
    }
}
