//
//  MarketingCampaignsMatchingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("MarketingCampaignsRepository token matching", .tags(.marketingBanners))
struct MarketingCampaignsMatchingTests {
    private typealias Fixtures = MarketingCampaignsFixtures

    private let ethereumCoin: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    private let usdtToken: TokenItem = .token(
        .init(name: "USDT", symbol: "USDT", contractAddress: "0xAbCdEf", decimalCount: 6),
        .init(.ethereum(testnet: false), derivationPath: nil)
    )

    @Test("Campaign with nil or empty tokens applies to nothing")
    func nilOrEmptyTokensNeverApply() {
        let withNilTokens = Fixtures.makeCampaign(tokens: nil)
        let withEmptyTokens = Fixtures.makeCampaign(tokens: [])

        #expect(!MarketingCampaignsRepository.appliesTo(withNilTokens, tokenItem: ethereumCoin))
        #expect(!MarketingCampaignsRepository.appliesTo(withEmptyTokens, tokenItem: ethereumCoin))
        #expect(!MarketingCampaignsRepository.appliesTo(withNilTokens, coingeckoId: "ethereum"))
        #expect(!MarketingCampaignsRepository.appliesTo(withEmptyTokens, coingeckoId: "ethereum"))
    }

    @Test("Coin matches on networkId when both contract addresses are nil")
    func coinMatchesOnNetworkId() {
        let campaign = Fixtures.makeCampaign(tokens: [Fixtures.makeToken(networkId: "ethereum")])

        #expect(MarketingCampaignsRepository.appliesTo(campaign, tokenItem: ethereumCoin))
    }

    @Test("Different networkId never matches")
    func differentNetworkIdDoesNotMatch() {
        let campaign = Fixtures.makeCampaign(tokens: [Fixtures.makeToken(networkId: "solana")])

        #expect(!MarketingCampaignsRepository.appliesTo(campaign, tokenItem: ethereumCoin))
    }

    @Test("Contract addresses are compared case-insensitively")
    func contractAddressComparisonIsCaseInsensitive() {
        let campaign = Fixtures.makeCampaign(tokens: [
            Fixtures.makeToken(networkId: "ethereum", contractAddress: "0xABCDEF"),
        ])

        #expect(MarketingCampaignsRepository.appliesTo(campaign, tokenItem: usdtToken))
    }

    @Test("Different contract address on the same network does not match")
    func differentContractAddressDoesNotMatch() {
        let campaign = Fixtures.makeCampaign(tokens: [
            Fixtures.makeToken(networkId: "ethereum", contractAddress: "0x123456"),
        ])

        #expect(!MarketingCampaignsRepository.appliesTo(campaign, tokenItem: usdtToken))
    }

    @Test("One-sided contract address never matches")
    func oneSidedContractAddressDoesNotMatch() {
        let campaignForToken = Fixtures.makeCampaign(tokens: [
            Fixtures.makeToken(networkId: "ethereum", contractAddress: "0xAbCdEf"),
        ])
        let campaignForCoin = Fixtures.makeCampaign(tokens: [
            Fixtures.makeToken(networkId: "ethereum"),
        ])

        #expect(!MarketingCampaignsRepository.appliesTo(campaignForToken, tokenItem: ethereumCoin))
        #expect(!MarketingCampaignsRepository.appliesTo(campaignForCoin, tokenItem: usdtToken))
    }

    @Test("Any matching token in the list is enough")
    func anyMatchingTokenApplies() {
        let campaign = Fixtures.makeCampaign(tokens: [
            Fixtures.makeToken(networkId: "solana"),
            Fixtures.makeToken(networkId: "ethereum"),
        ])

        #expect(MarketingCampaignsRepository.appliesTo(campaign, tokenItem: ethereumCoin))
    }

    @Test("Markets matching compares the coingecko id")
    func marketsMatchingComparesCoingeckoId() {
        let campaign = Fixtures.makeCampaign(tokens: [
            Fixtures.makeToken(id: "bitcoin"),
            Fixtures.makeToken(id: "ethereum"),
        ])

        #expect(MarketingCampaignsRepository.appliesTo(campaign, coingeckoId: "bitcoin"))
        #expect(MarketingCampaignsRepository.appliesTo(campaign, coingeckoId: "ethereum"))
        #expect(!MarketingCampaignsRepository.appliesTo(campaign, coingeckoId: "solana"))
    }
}
