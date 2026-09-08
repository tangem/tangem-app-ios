//
//  PortfolioReviewOutdatedDataResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("PortfolioReviewOutdatedDataResolver")
struct PortfolioReviewOutdatedDataResolverTests {
    typealias SUT = PortfolioReviewOutdatedDataResolver

    private let bitcoin = TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
    private let ethereum = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

    private let loadedChart = PortfolioReviewViewModel.ViewState.Chart.loaded(assets: [], assetCount: 1, topHoldingPercent: "100%")

    @Test("Failure of a displayed token shows the banner, with or without a cached balance", arguments: [Decimal(10), nil])
    func failedDisplayedToken(cached: Decimal?) {
        #expect(SUT.isOutdated(.failed(cached: cached, failedItems: [bitcoin]), displayedItems: [bitcoin, ethereum], chart: loadedChart))
    }

    @Test("Failure of a token outside the displayed set does not show the banner")
    func failedTokenOutsideDisplayedSet() {
        #expect(!SUT.isOutdated(.failed(cached: 10, failedItems: [ethereum]), displayedItems: [bitcoin], chart: loadedChart))
    }

    @Test("An undrawn donut carries no banner, even with a displayed failure", arguments: [
        PortfolioReviewViewModel.ViewState.Chart.noData(.cantLoad),
        .noData(.noAmount),
        nil,
    ])
    func unchartedDonutHidesBanner(chart: PortfolioReviewViewModel.ViewState.Chart?) {
        #expect(!SUT.isOutdated(.failed(cached: nil, failedItems: [bitcoin]), displayedItems: [bitcoin], chart: chart))
    }

    @Test("A state without a failure does not show the banner", arguments: [
        TotalBalanceState.loaded(balance: 10),
        .loading(cached: 10),
        .loading(cached: nil),
        .empty,
    ])
    func stateWithoutFailure(_ state: TotalBalanceState) {
        #expect(!SUT.isOutdated(state, displayedItems: [bitcoin], chart: loadedChart))
    }
}
