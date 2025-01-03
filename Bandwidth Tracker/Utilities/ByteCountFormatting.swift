//
//  ByteCountFormatting.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import Foundation

struct ByteCountFormatting {
    static func string(fromByteCount bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
    
    static func string(fromBytesPerSecond bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes)) + "/s"
    }
}
