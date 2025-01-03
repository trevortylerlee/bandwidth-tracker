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

@main
struct BandwidthTrackerApp: App {
    @StateObject private var monitor = NetworkMonitor()
    @StateObject private var settings = AppSettings()
    
    var body: some Scene {
        MenuBarExtra {
            PopoverView(monitor: monitor, settings: settings)
        } label: {
            MenuBarView(monitor: monitor, settings: settings)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView(settings: settings)
        }
    }
}
