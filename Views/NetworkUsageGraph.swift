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
    
    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Download", point.downloadBytes),
                    series: .value("Type", "Download")
                )
                .foregroundStyle(.blue)
                
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Upload", point.uploadBytes),
                    series: .value("Type", "Upload")
                )
                .foregroundStyle(.orange)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let bytes = value.as(Int64.self) {
                        Text(ByteCountFormatting.string(fromByteCount: bytes))
                    }
                }
            }
        }
        .frame(height: 200)
        .padding()
    }
}
