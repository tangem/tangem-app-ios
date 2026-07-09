//
//  POLStakingTransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Validates POL (ex-MATIC) staking transactions on Ethereum by checking for the StakeKit contract or a POL token approve.
public enum POLStakingTransactionValidator {
    /// StakeKit staking contract on Ethereum mainnet — the `to` for direct staking calls and the approve spender.
    static let stakeKitContract = "0x5e3Ef299fDDf15eAa0432E6e66473ace8c13D908"
    /// POL token contract.
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

        // Direct staking transaction to the StakeKit contract.
        if transaction.to.caseInsensitiveEquals(to: Self.stakeKitContract) {
            return
        }

        // Otherwise it must be an approve on the POL token with the StakeKit contract as spender.
        if transaction.to.caseInsensitiveEquals(to: Self.polToken) {
            try validateApproveTransaction(transaction)
            return
        }

        throw StakingTransactionValidationError.notAStakingTransaction(
            network: "Ethereum",
            details: "Transaction 'to' address '\(transaction.to)' is not a valid POL staking destination"
        )
    }

    /// Validates that the transaction is an ERC20 approve call with the StakeKit contract as spender.
    private static func validateApproveTransaction(_ transaction: EthereumCompiledTransactionData) throws {
        guard transaction.data.caseInsensitiveHasPrefix(approveMethodId) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Ethereum",
                details: "Transaction data does not contain approve method ID"
            )
        }

        let dataWithoutPrefix = transaction.data.removeHexPrefix()

        // methodID (8 chars) + spender word (64 chars) = 72 chars minimum
        guard dataWithoutPrefix.count >= 72 else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Ethereum",
                details: "Transaction data is too short for approve call"
            )
        }

        // Spender is the 32-byte word after the method ID; the address is its last 20 bytes.
        let spenderPadded = String(dataWithoutPrefix.dropFirst(8).prefix(64))
        let spenderAddress = String(spenderPadded.suffix(40)).addHexPrefix()

        guard spenderAddress.caseInsensitiveEquals(to: Self.stakeKitContract) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Ethereum",
                details: "Approve spender '\(spenderAddress)' is not the StakeKit staking contract"
            )
        }
    }
}
