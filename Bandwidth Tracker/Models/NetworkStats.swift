//
//  NetworkStats.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import Foundation

struct NetworkStats: Codable {
    var isMonitoring: Bool = false
    var sessionDuration: TimeInterval = 0
    
    var uploadSpeed: Double = 0
    var downloadSpeed: Double = 0
    
    var totalUploaded: Int64 = 0
    var totalDownloaded: Int64 = 0
    
    var lastKnownUploadBytes: Int64 = 0
    var lastKnownDownloadBytes: Int64 = 0
}

struct NetworkDataPoint: Codable, Identifiable {
    var id: UUID
    let timestamp: Date
    let uploadBytes: Int64
    let downloadBytes: Int64
    
    init(id: UUID = UUID(), timestamp: Date, uploadBytes: Int64, downloadBytes: Int64) {
        self.id = id
        self.timestamp = timestamp
        self.uploadBytes = uploadBytes
        self.downloadBytes = downloadBytes
    }
}
