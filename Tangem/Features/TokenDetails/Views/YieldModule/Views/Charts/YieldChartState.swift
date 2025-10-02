//
//  YieldChartState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum YieldChartState: Identifiable, Equatable {
    case loading
    case error(action: () async -> Void)
    case loaded(YieldChartData)

    var isLoading: Bool {
        if case .loading = self {
            return true
        } else {
            return false
        }
    }

    var isError: Bool {
        if case .error = self {
            return true
        } else {
            return false
        }
    }

    var id: String {
        switch self {
        case .loading:
            return "loading"
        case .error:
            return "error"
        case .loaded:
            return "loaded"
        }
    }

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
