//
//  YieldModuleChartView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct YieldModuleChartData: Identifiable, Equatable {
    private let fallbackId = UUID().uuidString
    let annualEarnings: [String: Double]

    var id: String {
        guard !annualEarnings.isEmpty else { return fallbackId }
        return annualEarnings.map { "\($0.key):\($0.value)" }.joined(separator: "|")
    }
}

struct YieldModuleChartView: View {
    let model: YieldModuleChartData
    var body: some View {
        Text("WIP Charts")
    }
}
