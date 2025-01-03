//
//  AppSettings.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//


import Foundation

class AppSettings: ObservableObject {
    enum DisplayMode: String, Codable {
        case speedInMenuBar
        case totalInMenuBar
        
        var popoverLabels: (download: String, upload: String) {
            switch self {
            case .speedInMenuBar:
                return (download: "Total Download:", upload: "Total Upload:")
            case .totalInMenuBar:
                return (download: "Download Speed:", upload: "Upload Speed:")
            }
        }
    }
    
    @Published var displayMode: DisplayMode {
        didSet {
            save()
        }
    }
    
    private let defaults = UserDefaults.standard
    private let displayModeKey = "displayMode"
    
    init() {
        if let savedMode = defaults.string(forKey: displayModeKey),
           let mode = DisplayMode(rawValue: savedMode) {
            self.displayMode = mode
        } else {
            self.displayMode = .totalInMenuBar
        }
    }
    
    private func save() {
        defaults.set(displayMode.rawValue, forKey: displayModeKey)
    }
}
