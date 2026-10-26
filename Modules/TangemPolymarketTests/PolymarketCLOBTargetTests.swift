//
//  PolymarketCLOBTargetTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Alamofire
import Moya
@testable import TangemPolymarket

@Suite("PolymarketCLOBTarget balance allowance")
struct PolymarketCLOBTargetBalanceAllowanceTests {
    @Test("Collateral is refreshed without a token", arguments: [
        PolymarketCLOBTarget.Target.updateBalanceAllowance(.collateral),
        .balanceAllowance,
    ])
    func collateralCarriesNoToken(_ target: PolymarketCLOBTarget.Target) throws {
        let parameters = try Self.parameters(target)

        #expect(parameters["asset_type"] as? String == "COLLATERAL")
        #expect(parameters["signature_type"] as? Int == 3)
        #expect(parameters.count == 2)
    }

    @Test("A position is refreshed under its version's asset type with its token", arguments: [
        (PolymarketBalanceAllowanceAsset.conditional(tokenId: "47"), "CONDITIONAL"),
        (PolymarketBalanceAllowanceAsset.conditionalV2(tokenId: "47"), "CONDITIONAL-V2"),
    ])
    func positionCarriesItsToken(_ asset: PolymarketBalanceAllowanceAsset, _ assetType: String) throws {
        let parameters = try Self.parameters(.updateBalanceAllowance(asset))

        #expect(parameters["asset_type"] as? String == assetType)
        #expect(parameters["token_id"] as? String == "47")
        #expect(parameters["signature_type"] as? Int == 3)
        #expect(parameters.count == 3)
    }

    @Test("A position of a market version this build does not know has nothing to refresh")
    func unknownVersionHasNoAsset() {
        #expect(PolymarketBalanceAllowanceAsset.position(tokenId: "47", version: .v1) == .conditional(tokenId: "47"))
        #expect(PolymarketBalanceAllowanceAsset.position(tokenId: "47", version: .v2) == .conditionalV2(tokenId: "47"))
        #expect(PolymarketBalanceAllowanceAsset.position(tokenId: "47", version: .unknown("v3")) == nil)
    }
}

@Suite("PolymarketCLOBTarget price history")
struct PolymarketCLOBTargetPriceHistoryTests {
    @Test("Price history asks for the token's market over the interval on the given grid")
    func priceHistoryQuery() throws {
        let target = PolymarketCLOBTarget.Target.priceHistory(tokenId: "47", query: .interval(.week, fidelityMinutes: 30))
        let sut = PolymarketCLOBTarget(baseURL: URL(string: "https://clob.polymarket.com")!, target: target, authHeaders: [:])
        let parameters = try PolymarketCLOBTargetBalanceAllowanceTests.parameters(target)

        #expect(sut.signedPath == "/prices-history")
        #expect(sut.method == .get)
        #expect(parameters["market"] as? String == "47")
        #expect(parameters["interval"] as? String == "1w")
        #expect(parameters["fidelity"] as? Int == 30)
        #expect(parameters.count == 3)
    }

    @Test("A closed market's history is asked between its start and its close, with no interval")
    func boundedRangeQuery() throws {
        let query = PolymarketPriceHistoryQuery.range(
            start: Date(timeIntervalSince1970: 1_787_490_038),
            end: Date(timeIntervalSince1970: 1_788_034_666.9),
            fidelityMinutes: 30
        )
        let target = PolymarketCLOBTarget.Target.priceHistory(tokenId: "47", query: query)
        let sut = PolymarketCLOBTarget(baseURL: URL(string: "https://clob.polymarket.com")!, target: target, authHeaders: [:])
        let parameters = try PolymarketCLOBTargetBalanceAllowanceTests.parameters(target)

        #expect(sut.signedPath == "/prices-history")
        #expect(sut.method == .get)
        #expect(parameters["market"] as? String == "47")
        #expect(parameters["startTs"] as? Int == 1_787_490_038)
        #expect(parameters["endTs"] as? Int == 1_788_034_666)
        #expect(parameters["fidelity"] as? Int == 30)
        #expect(parameters["interval"] == nil)
        #expect(parameters.count == 4)
    }

    @Test("A history that runs up to now is asked from the market's start only")
    func openRangeQuery() throws {
        let query = PolymarketPriceHistoryQuery.range(start: Date(timeIntervalSince1970: 1_792_641_610), end: nil, fidelityMinutes: 5)
        let parameters = try PolymarketCLOBTargetBalanceAllowanceTests.parameters(.priceHistory(tokenId: "47", query: query))

        #expect(parameters["market"] as? String == "47")
        #expect(parameters["startTs"] as? Int == 1_792_641_610)
        #expect(parameters["fidelity"] as? Int == 5)
        #expect(parameters["endTs"] == nil)
        #expect(parameters["interval"] == nil)
        #expect(parameters.count == 3)
    }
}

// MARK: - Helpers

private extension PolymarketCLOBTargetBalanceAllowanceTests {
    enum TestError: Error {
        case notRequestParameters
    }

    static func parameters(_ target: PolymarketCLOBTarget.Target) throws -> [String: Any] {
        let sut = PolymarketCLOBTarget(baseURL: URL(string: "https://clob.polymarket.com")!, target: target, authHeaders: [:])

        guard case .requestParameters(let parameters, _) = sut.task else {
            throw TestError.notRequestParameters
        }

        return parameters
    }
}
