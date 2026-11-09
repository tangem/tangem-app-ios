//
//  PolymarketPositionsValueTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
@testable import TangemPolymarket

// MARK: - Target

@Suite("Polymarket positions value target", .timeLimit(.minutes(1)))
struct PolymarketPositionsValueTargetTests {
    private let baseURL = URL(string: "https://data-api.polymarket.com")!
    private let depositWalletAddress = "0xdef0000000000000000000000000000000000005"

    private var target: PolymarketPositionsValueTarget {
        PolymarketPositionsValueTarget(baseURL: baseURL, depositWalletAddress: depositWalletAddress)
    }

    @Test("The call goes straight to Polymarket, so it carries no wallet id of ours")
    func noWalletIdHeader() {
        #expect(target.headers == nil)
    }
}

// MARK: - Response mapping

@Suite("Polymarket positions value mapping", .timeLimit(.minutes(1)))
struct PolymarketPositionsValueMappingTests {
    @Test("The value inside the data envelope is the amount held in bets")
    func valueIsTheAmount() throws {
        let response = try decode(#"{"data":{"proxy_wallet":"0xdead","value":4.7834}}"#)

        #expect(CommonPolymarketPositionsValueService.positionsValue(from: response) == Decimal(string: "4.7834"))
    }

    @Test("A wallet without positions reads as zero, not as an absent value")
    func emptyWalletIsZero() throws {
        let response = try decode(#"{"data":{"proxy_wallet":"0xdead","value":0.0}}"#)

        #expect(CommonPolymarketPositionsValueService.positionsValue(from: response) == .zero)
    }

    @Test("A whole-dollar amount keeps its exact value through Decimal")
    func wholeAmountSurvivesDecoding() throws {
        let response = try decode(#"{"data":{"proxy_wallet":"0xdead","value":22.77}}"#)

        #expect(CommonPolymarketPositionsValueService.positionsValue(from: response) == Decimal(string: "22.77"))
    }

    private func decode(_ json: String) throws -> PolymarketDTO.PositionsValueResponse {
        try JSONDecoder().decode(PolymarketDTO.PositionsValueResponse.self, from: Data(json.utf8))
    }
}
