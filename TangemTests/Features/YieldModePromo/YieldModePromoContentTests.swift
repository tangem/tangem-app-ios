//
//  YieldModePromoContentTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("YieldModePromoContent")
struct YieldModePromoContentTests {
    private let candidate = YieldModePromoCandidateResolver.Candidate(
        chainId: 1,
        contractAddress: "0xaaa",
        tokenSymbol: "USDT",
        blockchainName: "Ethereum",
        apy: Decimal(string: "0.061249")!,
        fiatBalance: 10
    )

    @Test("The top offer comes from the first Earn row and the count from the list total")
    func buildsOffers() throws {
        let content = try #require(YieldModePromoContent(candidate: candidate, earnResponse: response(total: 42, topApy: "0.092")))

        #expect(content.topData == YieldModePromoSheetData(apy: Decimal(string: "0.092")!, tokensCount: 42, tokenSymbol: "DAI", blockchainName: "Polygon"))
        #expect(content.candidateData == YieldModePromoSheetData(apy: Decimal(string: "0.0612")!, tokensCount: 42, tokenSymbol: "USDT", blockchainName: "Ethereum"))
    }

    @Test("Both rates are rounded to two percent decimals, half up, before the card and the events format them")
    func roundsRatesHalfUp() throws {
        let midpointCandidate = YieldModePromoCandidateResolver.Candidate(
            chainId: 1,
            contractAddress: "0xaaa",
            tokenSymbol: "USDT",
            blockchainName: "Ethereum",
            apy: Decimal(string: "0.06125")!,
            fiatBalance: 10
        )

        let content = try #require(YieldModePromoContent(candidate: midpointCandidate, earnResponse: response(total: 42, topApy: "0.09125")))

        #expect(content.candidateData.apy == Decimal(string: "0.0613"))
        #expect(content.topData.apy == Decimal(string: "0.0913"))
        #expect(CommonYieldModePromoAnalyticsLogger.formatAPY(content.candidateData.apy) == "6.13")
    }

    @Test("An Earn list without a top row gives no content")
    func listWithoutTopRowHasNoContent() {
        #expect(YieldModePromoContent(candidate: candidate, earnResponse: response(total: 0, topApy: nil)) == nil)
    }

    @Test("A top row without a positive rate gives no content")
    func topRowWithoutRateHasNoContent() {
        #expect(YieldModePromoContent(candidate: candidate, earnResponse: response(total: 5, topApy: "0")) == nil)
    }

    private func response(total: Int, topApy: String?) -> EarnDTO.List.Response {
        let items = topApy.map {
            [
                EarnDTO.List.Item(
                    apy: $0,
                    networkId: "polygon-pos",
                    rewardType: "apy",
                    type: "yield",
                    token: EarnDTO.List.Token(id: "dai", symbol: "DAI", name: "Dai", address: "0xdai", decimalCount: 18)
                ),
            ]
        } ?? []

        return EarnDTO.List.Response(items: items, meta: EarnDTO.List.Meta(page: 1, limit: 20, total: total, hasNext: false))
    }
}
