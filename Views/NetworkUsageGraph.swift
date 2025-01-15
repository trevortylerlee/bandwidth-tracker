//
//  NetworkUsageGraph.swift
//  Bandwidth Tracker
//
//  Created by Trevor Lee on 2025-01-03.
//

import SwiftUI
import Charts

struct NetworkUsageGraph: View {
    let dataPoints: [NetworkDataPoint]
    
    private var yAxisRange: (min: Int64, max: Int64) {
        let maxValue = dataPoints.map { max($0.downloadBytes, $0.uploadBytes) }.max() ?? 0
        let minValue = dataPoints.map { min($0.downloadBytes, $0.uploadBytes) }.min() ?? 0
        
        // Find the lowest non-zero value to use as minimum
        let lowestNonZero = dataPoints.map {
            min($0.downloadBytes > 0 ? $0.downloadBytes : .max,
                $0.uploadBytes > 0 ? $0.uploadBytes : .max)
        }.min() ?? 0
        
        // Use the lowest non-zero value as minimum if it exists and is significantly smaller than max
        let effectiveMin = lowestNonZero < maxValue / 100 ? lowestNonZero : minValue
        let effectiveMax = Int64(Double(maxValue) * 1.1) // Add 10% margin
        
        return (effectiveMin, effectiveMax)
    }
    
    private func formatTimeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Download", point.downloadBytes),
                    series: .value("Type", "Download")
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom) // Smooth curve
                
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Upload", point.uploadBytes),
                    series: .value("Type", "Upload")
                )
                .foregroundStyle(.orange)
                .interpolationMethod(.catmullRom) // Smooth curve
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 4)) { value in // Reduced frequency of time labels
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatTimeLabel(date))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 6)) { value in // Reduced number of y-axis labels
                AxisGridLine()
                AxisValueLabel {
                    if let bytes = value.as(Int64.self) {
                        Text(ByteCountFormatting.string(fromByteCount: bytes))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYScale(domain: yAxisRange.min...yAxisRange.max, type: .log) // Use logarithmic scale
        .chartLegend(position: .bottom) // Move legend to bottom
        .frame(height: 200)
        .padding()
    }
}
