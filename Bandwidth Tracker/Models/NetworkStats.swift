//
//  NetworkStats.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import Foundation

struct NetworkStats: Codable {
    var uploadSpeed: Double = 0
    var downloadSpeed: Double = 0
    var totalUploaded: Int64 = 0
    var totalDownloaded: Int64 = 0
    var startTime: Date
    var isMonitoring: Bool
    var dataPoints: [NetworkDataPoint] = []
    var lastKnownUploadBytes: Int64 = 0
    var lastKnownDownloadBytes: Int64 = 0
    var sessionDuration: TimeInterval = 0
    
    init() {
        startTime = Date()
        isMonitoring = true
        totalUploaded = 0
        totalDownloaded = 0
        lastKnownUploadBytes = 0
        lastKnownDownloadBytes = 0
    }
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
