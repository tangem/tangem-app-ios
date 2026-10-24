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
            Fixtures.makeEligibleToken(tokenAddress: "0xA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48", networkId: "ethereum"),
        ])

        #expect(isEligible(usdcOnEthereum))
    }

    @Test("Same contract address on a different network does not match")
    func differentNetworkDoesNotMatch() {
        let isEligible = EligibleTokenMatcher.make(from: [
            Fixtures.makeEligibleToken(networkId: "polygon-pos"),
        ])

        #expect(!isEligible(usdcOnEthereum))
    }

    @Test("Different contract address on the same network does not match")
    func differentContractAddressDoesNotMatch() {
        let isEligible = EligibleTokenMatcher.make(from: [
            Fixtures.makeEligibleToken(tokenAddress: "0x123456", networkId: "ethereum"),
        ])

        #expect(!isEligible(usdcOnEthereum))
    }

    @Test("Coin without a contract address never matches")
    func coinNeverMatches() {
        let isEligible = EligibleTokenMatcher.make(from: [
            Fixtures.makeEligibleToken(networkId: "ethereum"),
        ])

        #expect(!isEligible(ethereumCoin))
    }

    @Test("A token item finds the listed token with the same network and contract address")
    func tokenMatchingTokenItem() {
        let listed = Fixtures.makeEligibleToken(tokenAddress: "0xA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48", networkId: "ethereum")
        let tokens = [Fixtures.makeEligibleToken(tokenAddress: "0x123456", networkId: "ethereum"), listed]

        #expect(EligibleTokenMatcher.token(matching: usdcOnEthereum, in: tokens) == listed)
        #expect(EligibleTokenMatcher.token(matching: ethereumCoin, in: tokens) == nil)
    }

    @Test("A network and contract address find the listed token regardless of address casing")
    func tokenMatchingNetworkAndAddress() {
        let listed = Fixtures.makeEligibleToken(tokenAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", networkId: "ethereum")

        #expect(EligibleTokenMatcher.token(networkId: "ethereum", contractAddress: "0xA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48", in: [listed]) == listed)
        #expect(EligibleTokenMatcher.token(networkId: "polygon-pos", contractAddress: listed.tokenAddress, in: [listed]) == nil)
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
            Fixtures.makeEligibleToken(tokenAddress: "0x123456", networkId: "solana"),
            Fixtures.makeEligibleToken(networkId: "ethereum"),
        ])

        #expect(isEligible(usdcOnEthereum))
    }
}
