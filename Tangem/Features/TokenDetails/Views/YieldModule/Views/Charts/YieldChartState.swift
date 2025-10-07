//
//  YieldChartState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum YieldChartState: Equatable {
    case loading
    case error(action: () async -> Void)
    case loaded(YieldChartData)

    static func == (lhs: YieldChartState, rhs: YieldChartState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.error, .error):
            return true
        case (.loaded(let lhsData), .loaded(let rhsData)):
            return lhsData == rhsData
        default:
            return false
        }
    }
}
