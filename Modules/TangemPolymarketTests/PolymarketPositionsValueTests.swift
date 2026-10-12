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

@Suite("Polymarket positions value target")
struct PolymarketPositionsValueTargetTests {
    private let baseURL = URL(string: "https://data-api.polymarket.com")!
    private let depositWalletAddress = "0x0414510dff186394a272341071ba2feeddf40a25"

    private var target: PolymarketPositionsValueTarget {
        PolymarketPositionsValueTarget(baseURL: baseURL, depositWalletAddress: depositWalletAddress)
    }

    @Test("Path and method")
    func pathAndMethod() {
        #expect(target.path == "value")
        #expect(target.method == .get)
    }

    @Test("The deposit wallet goes into the query under the name the API expects")
    func depositWalletGoesIntoTheQuery() throws {
        guard case .requestParameters(let parameters, let encoding) = target.task else {
            throw TestError.notRequestParameters
        }

        #expect(parameters as? [String: String] == ["user": depositWalletAddress])
        #expect(encoding is URLEncoding)
    }

    @Test("The call goes straight to Polymarket, so it carries no wallet id of ours")
    func noWalletIdHeader() {
        #expect(target.headers == nil)
    }

    private enum TestError: Error {
        case notRequestParameters
    }
}

// MARK: - Response mapping

@Suite("Polymarket positions value mapping")
struct PolymarketPositionsValueMappingTests {
    @Test("The value of the first entry is the amount held in bets")
    func firstEntryIsTheAmount() throws {
        let response = try decode(#"[{"user":"0xdead","value":7.792}]"#)

        #expect(CommonPolymarketPositionsValueService.positionsValue(from: response) == Decimal(string: "7.792"))
    }

    @Test("An empty array means no open positions, which is zero and not an absent value")
    func emptyArrayIsZero() throws {
        let response = try decode("[]")

        #expect(CommonPolymarketPositionsValueService.positionsValue(from: response) == .zero)
    }

    @Test("Only the first entry counts, the rest are somebody else's rows")
    func onlyTheFirstEntryCounts() throws {
        let response = try decode(#"[{"user":"0xdead","value":7.792},{"user":"0xbeef","value":100}]"#)

        #expect(CommonPolymarketPositionsValueService.positionsValue(from: response) == Decimal(string: "7.792"))
    }

    @Test("A whole-dollar amount keeps its exact value through Decimal")
    func wholeAmountSurvivesDecoding() throws {
        let response = try decode(#"[{"user":"0xdead","value":22.77}]"#)

        #expect(CommonPolymarketPositionsValueService.positionsValue(from: response) == Decimal(string: "22.77"))
    }

    private func decode(_ json: String) throws -> [PolymarketDTO.PositionsValueResponse] {
        try JSONDecoder().decode([PolymarketDTO.PositionsValueResponse].self, from: Data(json.utf8))
    }
}
