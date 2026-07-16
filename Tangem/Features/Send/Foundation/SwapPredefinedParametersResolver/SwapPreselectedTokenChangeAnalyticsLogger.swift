//
//  SwapPreselectedTokenChangeAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class SwapPreselectedTokenChangeAnalyticsLogger {
    private var preselectedSourceTokenItem: TokenItem?
    private var preselectedReceiveTokenItem: TokenItem?
    private let analyticsLogger: SwapManagementModelAnalyticsLogger

    init(
        preselectedSourceTokenItem: TokenItem?,
        preselectedReceiveTokenItem: TokenItem?,
        analyticsLogger: SwapManagementModelAnalyticsLogger
    ) {
        self.preselectedSourceTokenItem = preselectedSourceTokenItem
        self.preselectedReceiveTokenItem = preselectedReceiveTokenItem
        self.analyticsLogger = analyticsLogger
    }

    func logIfNeeded(direction: Direction, selected: TokenItem) {
        let preselected: TokenItem? = switch direction {
        case .source: preselectedSourceTokenItem
        case .receive: preselectedReceiveTokenItem
        }

        guard let preselected, preselected != selected else {
            return
        }

        clearPreselected(direction: direction)

        analyticsLogger.logSwapPreselectedTokenChanged(
            direction: direction.analyticsValue,
            preselectedSymbol: preselected.currencySymbol,
            selectedSymbol: selected.currencySymbol
        )
    }

    private func clearPreselected(direction: Direction) {
        switch direction {
        case .source: preselectedSourceTokenItem = nil
        case .receive: preselectedReceiveTokenItem = nil
        }
    }
}

// MARK: - Direction

extension SwapPreselectedTokenChangeAnalyticsLogger {
    enum Direction {
        case source
        case receive

        fileprivate var analyticsValue: Analytics.ParameterValue {
            switch self {
            case .source: .from
            case .receive: .to
            }
        }
    }
}
