//
//  ForYouAnalyticsLoggerStub.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Keeps previews and fixtures out of the analytics stream.
struct ForYouAnalyticsLoggerStub: ForYouAnalyticsLogger {
    func logScreenOpened() {}
    func logAccountFilterOpened() {}
    func logApplySelected() {}
    func logFilterInterval(period: TokenSummaryPeriod) {}
    func logDiagramTap() {}
    func logExploreAllTokens() {}
    func logEarnTokenOpened(tokenItem: TokenItem, product: EarnApyInfo.Product) {}
}

struct TokenSummaryAnalyticsLoggerStub: TokenSummaryAnalyticsLogger {
    func logOpened() {}
    func logInterval(period: TokenSummaryPeriod) {}
    func logPrimaryAction(kind: TokenSummaryPrimaryAction.Kind) {}
    func logIndicatorInfo(kind: TokenSummaryIndicator.Kind) {}
}
