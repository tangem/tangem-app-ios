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
    private let depositWalletAddress = "0xdef0000000000000000000000000000000000005"

    private var target: PolymarketPositionsValueTarget {
        PolymarketPositionsValueTarget(baseURL: baseURL, depositWalletAddress: depositWalletAddress)
    }

    @Test("Path and method")
    func pathAndMethod() {
        #expect(target.path == "v2/value")
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

    @Test("A plain zero reads as zero too")
    func integerZeroIsZero() throws {
        let response = try decode(#"{"data":{"proxy_wallet":"0xdead","value":0}}"#)

        #expect(CommonPolymarketPositionsValueService.positionsValue(from: response) == .zero)
    }

    @Test("A whole-dollar amount keeps its exact value through Decimal")
    func wholeAmountSurvivesDecoding() throws {
        let response = try decode(#"{"data":{"proxy_wallet":"0xdead","value":22.77}}"#)

        #expect(CommonPolymarketPositionsValueService.positionsValue(from: response) == Decimal(string: "22.77"))
    }

    @Test("The retired v1 array shape is not taken for a value")
    func legacyArrayIsRejected() {
        #expect(throws: DecodingError.self) {
            try decode(#"[{"user":"0xdead","value":7.792}]"#)
        }
    }

    private func decode(_ json: String) throws -> PolymarketDTO.PositionsValueResponse {
        try JSONDecoder().decode(PolymarketDTO.PositionsValueResponse.self, from: Data(json.utf8))
    }
}
