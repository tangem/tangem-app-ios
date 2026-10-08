//
//  P2PMapperTargetInfoTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemStaking

final class P2PMapperTargetInfoTests: XCTestCase {
    private let vaultAddress = "0x4c09BC47db288F998b33CD63BCc1b6ddCCe13F33"

    func testVaultWithRoomLeftIsAvailableToStake() throws {
        let target = try makeTargetInfo(totalAssets: "100", limit: 150)

        XCTAssertEqual(target.status, .active)
        XCTAssertTrue(target.preferred)
        XCTAssertEqual(target.maximumStakeAmount, 50)
        XCTAssertTrue(target.allowsPartialUnstake)
    }

    func testVaultWithoutLimitInfoIsFullButKeepsPartialUnstake() throws {
        let target = try makeTargetInfo(totalAssets: "100", limit: nil)

        XCTAssertEqual(target.status, .full)
        XCTAssertFalse(target.preferred)
        XCTAssertNil(target.maximumStakeAmount)
        XCTAssertTrue(target.allowsPartialUnstake)
    }

    func testVaultWithRoomBelowTheThresholdIsFullButKeepsPartialUnstake() throws {
        let target = try makeTargetInfo(totalAssets: "100", limit: Decimal(string: "100.05")!)

        XCTAssertEqual(target.status, .full)
        XCTAssertFalse(target.preferred)
        XCTAssertTrue(target.allowsPartialUnstake)
    }
}

// MARK: - Helpers

private extension P2PMapperTargetInfoTests {
    func makeTargetInfo(totalAssets: String, limit: Decimal?) throws -> StakingTargetInfo {
        let json = """
        {
            "network": "ethereum",
            "vaults": [
                {
                    "vaultAddress": "\(vaultAddress)",
                    "displayName": "Tangem Vault",
                    "apy": 3.1,
                    "baseApy": 3,
                    "capacity": null,
                    "totalAssets": "\(totalAssets)",
                    "feePercent": 10,
                    "isPrivate": false,
                    "isGenesis": false,
                    "isSmoothingPool": false,
                    "isErc20": false,
                    "tokenName": null,
                    "tokenSymbol": null,
                    "createdAt": "2026-08-11T09:00:00Z"
                }
            ]
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(P2PDTO.Vaults.VaultsInfo.self, from: Data(json.utf8))

        let limitInfos = limit.map { [vaultAddress.lowercased(): StakingTargetAmountLimitInfo(limit: $0, coefficient: nil)] } ?? [:]
        let yield = try P2PMapper().mapToYieldInfo(from: response, targetAmountInfos: limitInfos)

        return try XCTUnwrap(yield.targets.first)
    }
}
