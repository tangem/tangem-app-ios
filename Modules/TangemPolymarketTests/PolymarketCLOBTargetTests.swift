//
//  PolymarketCLOBTargetTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
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
