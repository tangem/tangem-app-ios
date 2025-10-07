//
//  YieldModuleChart.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct YieldModuleChart: View {
    // MARK: - State

    let state: State

    // MARK: - View Body

    var body: some View {
        if #available(iOS 16.0, *) {
            YieldModuleiOS16Chart(state: state)
                .frame(height: 110)
        } else {
            YieldModuleDGChartContainer(state: state)
                .frame(height: 110)
        }
    }
}

// MARK: - State

extension YieldModuleChart {
    enum State {
        case loading
        case loaded(apyData: [Double], xAxisLabels: [String], averageApy: Double?)

        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            case .loaded:
                return false
            }
        }
    }
}
