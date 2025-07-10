//
//  WCApprovalAnalyzer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemSdk

enum WCApprovalAnalyzer {
    // MARK: - Constants

    private static let approvalFunctionSelector = "0x095ea7b3"
    private static let expectedDataLengthWithPrefix = 138 // 0x + 68 bytes = 2 + 136 hex chars = 138 total
    private static let expectedDataLengthBytes = 68 // 4 bytes selector + 32 bytes spender + 32 bytes amount = 68 bytes

    static func analyzeApproval(transaction: WalletConnectEthTransaction,) -> ApprovalInfo? {
        guard isApprovalTransaction(transaction) else {
            return nil
        }

        guard let (spender, amount) = extractApprovalData(from: transaction.data) else { return nil }

        let isEditable = checkEditable(transaction: transaction, spender: spender)

        return ApprovalInfo(
            spender: spender,
            amount: amount,
            isUnlimited: amount == BigUInt.maxUInt256,
            isEditable: isEditable
        )
    }

    static func createUpdatedApproval(
        originalTransaction: WalletConnectEthTransaction,
        newAmount: BigUInt
    ) -> WalletConnectEthTransaction? {
        guard isApprovalTransaction(originalTransaction) else { return nil }

        guard let (spender, _) = extractApprovalData(from: originalTransaction.data) else { return nil }

        let newData = createApprovalData(spender: spender, amount: newAmount)

        return WalletConnectEthTransaction(
            from: originalTransaction.from,
            to: originalTransaction.to,
            value: originalTransaction.value,
            data: newData,
            gas: originalTransaction.gas,
            gasLimit: originalTransaction.gasLimit,
            gasPrice: originalTransaction.gasPrice,
            nonce: originalTransaction.nonce
        )
    }

    // MARK: - Private Methods

    private static func isApprovalTransaction(_ transaction: WalletConnectEthTransaction) -> Bool {
        guard transaction.data.isNotEmpty, transaction.to.isNotEmpty else { return false }

        return isValidApprovalData(transaction.data)
    }

    private static func isValidApprovalData(_ data: String) -> Bool {
        // 1. Check that after 0x follows "095ea7b3"
        guard data.hasPrefix(approvalFunctionSelector) else {
            return false
        }

        // 3. Check data length = 68 bytes (136 hex chars + 0x = 138 chars)
        guard data.count == expectedDataLengthWithPrefix else {
            return false
        }

        // Check that to address is not empty (should be token contract)
        return true
    }

    private static func extractApprovalData(from data: String?) -> (spender: String, amount: BigUInt)? {
        guard let data = data, data.hasPrefix(approvalFunctionSelector) else {
            return nil
        }

        // Remove "0x095ea7b3" prefix (10 chars)
        let parametersData = String(data.dropFirst(10))

        // Check that exactly 128 chars remain (64 bytes = 2 parameters of 32 bytes each)
        guard parametersData.count == 128 else {
            return nil
        }

        // Extract spender (first 64 chars, but take only last 40 for address)
        let spenderHex = String(parametersData.prefix(64).suffix(40))
        let spender = "0x" + spenderHex

        // Extract amount (next 64 chars)
        let amountHex = String(parametersData.suffix(64))
        guard let amount = BigUInt(amountHex, radix: 16) else {
            return nil
        }

        return (spender: spender, amount: amount)
    }

    private static func checkEditable(transaction: WalletConnectEthTransaction, spender: String) -> Bool {
        guard
            transaction.data.hasPrefix(approvalFunctionSelector),
            transaction.data.dropFirst(approvalFunctionSelector.count).hasPrefix(
                spender.removeHexPrefix().padLeft(toLength: 64, withPad: "0")
            ),
            transaction.data.count == expectedDataLengthWithPrefix
        else {
            return false
        }

        return true
    }

    private static func createApprovalData(spender: String, amount: BigUInt) -> String {
        // Remove 0x prefix from spender if present
        let cleanSpender = spender.removeHexPrefix()

        // Pad spender to 32 bytes (64 hex chars)
        let paddedSpender = cleanSpender.padLeft(toLength: 64, withPad: "0")

        // Convert amount to hex and pad to 32 bytes
        let amountHex = String(amount, radix: 16)
        let paddedAmount = amountHex.padLeft(toLength: 64, withPad: "0")

        // Combine: selector + spender + amount
        return approvalFunctionSelector + paddedSpender + paddedAmount
    }
}

// MARK: - String Extensions

private extension String {
    func padLeft(toLength: Int, withPad character: Character) -> String {
        let length = count
        if length < toLength {
            return String(repeating: character, count: toLength - length) + self
        } else {
            return self
        }
    }
}

// MARK: - Model Data

/// Information about approval transaction
struct ApprovalInfo: Equatable {
    let spender: String // Recipient address of allowance
    let amount: BigUInt // Allowance size in wei
    let isUnlimited: Bool // Is allowance unlimited
    let isEditable: Bool // Is allowance editable
}

// MARK: - Convenience Extensions

extension BigUInt {
    /// Maximum uint256 value
    static var maxUInt256: BigUInt {
        return BigUInt(2).power(256) - 1
    }
}

private extension String {
    /// Removes "0x" prefix if it exists
    func removeHexPrefix() -> String {
        if hasPrefix("0x") || hasPrefix("0X") {
            return String(dropFirst(2))
        }
        return self
    }
}
