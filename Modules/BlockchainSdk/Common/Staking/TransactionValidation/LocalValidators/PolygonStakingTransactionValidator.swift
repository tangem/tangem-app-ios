//
//  PolygonStakingTransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Validates Polygon staking transactions by checking for StakeKit contract or POL token approve.
public enum PolygonStakingTransactionValidator {
    static let stakeKitContract = "0x467585AaEa860F9D8B3B43bb994E4Da8A93788a7"
    static let polToken = "0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6"
    static let approveMethodId = "0x095ea7b3"

    public static func validate(_ unsignedData: String) throws {
        guard !unsignedData.isEmpty else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let data = Data(unsignedData.utf8)

        let transaction: EthereumCompiledTransactionData
        do {
            transaction = try JSONDecoder().decode(EthereumCompiledTransactionData.self, from: data)
        } catch {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let toAddress = transaction.to.lowercased()

        // Case 1: Direct staking transaction to StakeKit contract
        if toAddress == Self.stakeKitContract.lowercased() {
            return // Valid staking transaction
        }

        // Case 2: Approve transaction on POL token
        if toAddress == Self.polToken.lowercased() {
            try validateApproveTransaction(transaction)
            return // Valid approve transaction
        }

        throw StakingTransactionValidationError.notAStakingTransaction(
            network: "Polygon",
            details: "Transaction 'to' address '\(transaction.to)' is not a valid staking destination"
        )
    }

    /// Validates that the transaction is an ERC20 approve call with the expected spender.
    private static func validateApproveTransaction(_ transaction: EthereumCompiledTransactionData) throws {
        let txData = transaction.data.lowercased()

        // Check method ID (first 4 bytes = 8 hex chars + "0x" prefix)
        guard txData.hasPrefix(Self.approveMethodId.lowercased()) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Polygon",
                details: "Transaction data does not contain approve method ID"
            )
        }

        // Extract spender from data (first 32 bytes after method ID, but address is last 20 bytes)
        // Format: 0x095ea7b3 + 32 bytes spender (padded) + 32 bytes amount
        // Data always has "0x" prefix (verified by hasPrefix check above)
        let dataWithoutPrefix = String(txData.dropFirst(2))

        // methodID (8 chars) + spender (64 chars) = 72 chars minimum
        guard dataWithoutPrefix.count >= 72 else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Polygon",
                details: "Transaction data is too short for approve call"
            )
        }

        // Spender is bytes 4-36 (indices 8-72 in hex string), but only last 20 bytes are the address
        let spenderPadded = String(dataWithoutPrefix.dropFirst(8).prefix(64))
        let spenderAddress = "0x" + String(spenderPadded.suffix(40))

        guard spenderAddress.lowercased() == Self.stakeKitContract.lowercased() else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Polygon",
                details: "Approve spender '\(spenderAddress)' does not match StakeKit contract"
            )
        }
    }
}
