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
