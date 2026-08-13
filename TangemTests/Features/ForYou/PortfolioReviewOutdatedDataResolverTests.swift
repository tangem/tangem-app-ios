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
    private let bitcoin = TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
    private let ethereum = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

    @Test("Failure of a displayed token with a cached balance shows the banner")
    func failedDisplayedTokenWithCache() {
        #expect(PortfolioReviewOutdatedDataResolver.isOutdated(
            .failed(cached: 10, failedItems: [bitcoin]),
            displayedItems: [bitcoin, ethereum]
        ))
    }

    @Test("Failure of a token outside the displayed set does not show the banner")
    func failedTokenOutsideDisplayedSet() {
        #expect(!PortfolioReviewOutdatedDataResolver.isOutdated(
            .failed(cached: 10, failedItems: [ethereum]),
            displayedItems: [bitcoin]
        ))
    }

    @Test("Failure without a cached balance does not show the banner")
    func failedWithoutCache() {
        #expect(!PortfolioReviewOutdatedDataResolver.isOutdated(
            .failed(cached: nil, failedItems: [bitcoin]),
            displayedItems: [bitcoin]
        ))
    }

    @Test("Loaded balance does not show the banner")
    func loaded() {
        #expect(!PortfolioReviewOutdatedDataResolver.isOutdated(
            .loaded(balance: 10),
            displayedItems: [bitcoin]
        ))
    }

    @Test("Loading does not show the banner, with or without a cached balance")
    func loading() {
        #expect(!PortfolioReviewOutdatedDataResolver.isOutdated(.loading(cached: 10), displayedItems: [bitcoin]))
        #expect(!PortfolioReviewOutdatedDataResolver.isOutdated(.loading(cached: nil), displayedItems: [bitcoin]))
    }

    @Test("Empty state does not show the banner")
    func empty() {
        #expect(!PortfolioReviewOutdatedDataResolver.isOutdated(.empty, displayedItems: [bitcoin]))
    }
}
