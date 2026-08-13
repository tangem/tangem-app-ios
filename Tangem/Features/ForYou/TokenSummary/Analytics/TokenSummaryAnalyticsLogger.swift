//
//  TokenSummaryAnalyticsLogger.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Token Summary is presented from both For You and Markets, so its logger is built by whichever
/// entry point opens the screen.
protocol TokenSummaryAnalyticsLogger {
    func logOpened()
    func logInterval(period: TokenSummaryPeriod)
    func logPrimaryAction(kind: TokenSummaryPrimaryAction.Kind)
    func logIndicatorInfo(kind: TokenSummaryIndicator.Kind)
}
