//
//  EligibleTokenMatcherTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("EligibleTokenMatcher", .tags(.campaigns))
struct EligibleTokenMatcherTests {
    private typealias Fixtures = PromotionCampaignsFixtures

    private let ethereumCoin: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    private let usdcOnEthereum: TokenItem = .token(
        .init(name: "USD Coin", symbol: "USDC", contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", decimalCount: 6),
        .init(.ethereum(testnet: false), derivationPath: nil)
    )

    @Test("Token matches on networkId and contract address regardless of address casing")
    func matchesCaseInsensitively() {
        let isEligible = EligibleTokenMatcher.make(from: [
            Fixtures.makeToken(tokenAddress: "0xA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48", networkId: "ethereum"),
        ])

        #expect(isEligible(usdcOnEthereum))
    }

    @Test("Same contract address on a different network does not match")
    func differentNetworkDoesNotMatch() {
        let isEligible = EligibleTokenMatcher.make(from: [
            Fixtures.makeToken(networkId: "polygon-pos"),
        ])

        #expect(!isEligible(usdcOnEthereum))
    }

    @Test("Different contract address on the same network does not match")
    func differentContractAddressDoesNotMatch() {
        let isEligible = EligibleTokenMatcher.make(from: [
            Fixtures.makeToken(tokenAddress: "0x123456", networkId: "ethereum"),
        ])

        #expect(!isEligible(usdcOnEthereum))
    }

    @Test("Coin without a contract address never matches")
    func coinNeverMatches() {
        let isEligible = EligibleTokenMatcher.make(from: [
            Fixtures.makeToken(networkId: "ethereum"),
        ])

        #expect(!isEligible(ethereumCoin))
    }

    @Test("Empty eligible list matches nothing")
    func emptyListMatchesNothing() {
        let isEligible = EligibleTokenMatcher.make(from: [])

        #expect(!isEligible(usdcOnEthereum))
        #expect(!isEligible(ethereumCoin))
    }

    @Test("Any matching token in the list is enough")
    func anyMatchingTokenIsEnough() {
        let isEligible = EligibleTokenMatcher.make(from: [
            Fixtures.makeToken(tokenAddress: "0x123456", networkId: "solana"),
            Fixtures.makeToken(networkId: "ethereum"),
        ])

        #expect(isEligible(usdcOnEthereum))
    }
}
