//
//  POLStakingTransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Validates POL (ex-MATIC) staking transactions on Ethereum by checking for StakeKit contract or POL token approve.
public enum POLStakingTransactionValidator {
    /// dPOL6d receipt token contract (used for stake calls)
    static let stakeKitContract = "0x467585AaEa860F9D8B3B43bb994E4Da8A93788a7"
    /// Polygon PoS StakeManagerProxy on Ethereum mainnet (used as approve spender)
    static let stakeManagerProxy = "0x5e3Ef299fDDf15eAa0432E6e66473ace8c13D908"
    /// POL token contract
    static let polToken = "0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6"
    static let approveMethodId = "0x095ea7b3"

    /// Valid spenders for approve transactions
    static let validApproveSpenders: Set<String> = [
        stakeKitContract.lowercased(),
        stakeManagerProxy.lowercased(),
    ]

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

        // Case 1: Direct staking transaction to StakeKit contract
        if transaction.to.caseInsensitiveEquals(to: Self.stakeKitContract) {
            return
        }

        // Case 2: Approve transaction on POL token
        if transaction.to.caseInsensitiveEquals(to: Self.polToken) {
            try validateApproveTransaction(transaction)
            return
        }

        throw StakingTransactionValidationError.notAStakingTransaction(
            network: "Ethereum",
            details: "Transaction 'to' address '\(transaction.to)' is not a valid POL staking destination"
        )
    }

    /// Validates that the transaction is an ERC20 approve call with the expected spender.
    private static func validateApproveTransaction(_ transaction: EthereumCompiledTransactionData) throws {
        // Check method ID (first 4 bytes = 8 hex chars + "0x" prefix)
        guard transaction.data.caseInsensitiveHasPrefix(approveMethodId) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Ethereum",
                details: "Transaction data does not contain approve method ID"
            )
        }

        // Extract spender from data (first 32 bytes after method ID, but address is last 20 bytes)
        // Format: 0x095ea7b3 + 32 bytes spender (padded) + 32 bytes amount
        let dataWithoutPrefix = transaction.data.removeHexPrefix()

        // methodID (8 chars) + spender (64 chars) = 72 chars minimum
        guard dataWithoutPrefix.count >= 72 else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Ethereum",
                details: "Transaction data is too short for approve call"
            )
        }

        // Spender is bytes 4-36 (indices 8-72 in hex string), but only last 20 bytes are the address
        let spenderPadded = String(dataWithoutPrefix.dropFirst(8).prefix(64))
        let spenderAddress = String(spenderPadded.suffix(40)).addHexPrefix()

        guard Self.validApproveSpenders.contains(spenderAddress.lowercased()) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Ethereum",
                details: "Approve spender '\(spenderAddress)' is not a valid POL staking contract"
            )
        }
    }
}
