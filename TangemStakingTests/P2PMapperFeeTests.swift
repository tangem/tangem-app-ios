//
//  P2PMapperFeeTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemStaking

final class P2PMapperFeeTests: XCTestCase {
    private let walletAddress = "0xb1123efF798183B7Cb32F62607D3D39E950d9cc3"

    /// P2P quotes `maxFeePerGas` as the whole cap, tip included. The fee shown on the send screen must be
    /// computed from that cap alone — otherwise it disagrees with the cap the transaction is signed with.
    func testFeeUsesQuotedMaxFeePerGasWithoutAddingTheTipOnTop() throws {
        let info = try makeTransactionInfo(
            gasLimit: "226901",
            maxFeePerGas: "1000000000",
            maxPriorityFeePerGas: "100000000"
        )

        // 226_901 × 1 gwei / 1e18
        XCTAssertEqual(info.fee, Decimal(string: "0.000226901"))
    }

    func testZeroTipFeeMatchesTheQuotedCap() throws {
        let info = try makeTransactionInfo(
            gasLimit: "226901",
            maxFeePerGas: "1000000000",
            maxPriorityFeePerGas: "0"
        )

        XCTAssertEqual(info.fee, Decimal(string: "0.000226901"))
    }
}

// MARK: - Helpers

private extension P2PMapperFeeTests {
    func makeTransactionInfo(
        gasLimit: String,
        maxFeePerGas: String,
        maxPriorityFeePerGas: String
    ) throws -> StakingTransactionInfo {
        let json = """
        {
            "amount": 1,
            "vaultAddress": "0x4c09BC47db288F998b33CD63BCc1b6ddCCe13F33",
            "delegatorAddress": "\(walletAddress)",
            "createdAt": "2026-08-11T09:00:00Z",
            "unsignedTransaction": {
                "serializeTx": "0x02",
                "to": "0x4c09BC47db288F998b33CD63BCc1b6ddCCe13F33",
                "data": "0xd0e30db0",
                "value": "1000000000000000000",
                "nonce": 66,
                "chainId": 1,
                "gasLimit": "\(gasLimit)",
                "maxFeePerGas": "\(maxFeePerGas)",
                "maxPriorityFeePerGas": "\(maxPriorityFeePerGas)"
            }
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(
            P2PDTO.PrepareTransaction.PrepareTransactionInfo.self,
            from: Data(json.utf8)
        )

        return try P2PMapper().mapToStakingTransactionInfo(from: response, walletAddress: walletAddress)
    }
}
