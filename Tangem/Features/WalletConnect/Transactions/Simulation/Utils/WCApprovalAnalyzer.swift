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
    private static let approvalFunctionSelector = "0x095ea7b3"
    private static let expectedDataLengthWithPrefix = 138
    private static let expectedDataLengthBytes = 68

    static func analyzeApproval(transaction: WCSendableTransaction) -> ApprovalInfo? {
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
        originalTransaction: WCSendableTransaction,
        newAmount: BigUInt
    ) -> WCSendableTransaction? {
        guard isApprovalTransaction(originalTransaction) else { return nil }

        guard let (spender, _) = extractApprovalData(from: originalTransaction.data) else { return nil }

        let newData = createApprovalData(spender: spender, amount: newAmount)

        return originalTransaction.withUpdatedData(newData)
    }

    static func createApprovalData(spender: String, amount: BigUInt) -> String {
        let cleanSpender = spender.removeHexPrefix()

        let paddedSpender = cleanSpender.padLeft(toLength: 64, withPad: "0")

        let amountHex = String(amount, radix: 16)
        let paddedAmount = amountHex.padLeft(toLength: 64, withPad: "0")

        return approvalFunctionSelector + paddedSpender + paddedAmount
    }

    private static func isApprovalTransaction(_ transaction: WCSendableTransaction) -> Bool {
        guard let data = transaction.data, data.isNotEmpty, transaction.to.isNotEmpty else { return false }

        return isValidApprovalData(data)
    }

    private static func isValidApprovalData(_ data: String) -> Bool {
        guard data.hasPrefix(approvalFunctionSelector) else {
            return false
        }

        guard data.count == expectedDataLengthWithPrefix else {
            return false
        }

        return true
    }

    private static func extractApprovalData(from data: String?) -> (spender: String, amount: BigUInt)? {
        guard let data = data, data.hasPrefix(approvalFunctionSelector) else {
            return nil
        }

        let parametersData = String(data.dropFirst(10))

        guard parametersData.count == 128 else {
            return nil
        }

        let spenderHex = String(parametersData.prefix(64).suffix(40))
        let spender = "0x" + spenderHex

        let amountHex = String(parametersData.suffix(64))
        guard let amount = BigUInt(amountHex, radix: 16) else {
            return nil
        }

        return (spender: spender, amount: amount)
    }

    private static func checkEditable(transaction: WCSendableTransaction, spender: String) -> Bool {
        guard
            let data = transaction.data,
            data.hasPrefix(approvalFunctionSelector),
            data.dropFirst(approvalFunctionSelector.count).hasPrefix(
                spender.removeHexPrefix().padLeft(toLength: 64, withPad: "0")
            ),
            data.count == expectedDataLengthWithPrefix
        else {
            return false
        }

        return true
    }
}

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

struct ApprovalInfo: Equatable {
    let spender: String
    let amount: BigUInt
    let isUnlimited: Bool
    let isEditable: Bool
}

extension BigUInt {
    static var maxUInt256: BigUInt {
        return BigUInt(2).power(256) - 1
    }
}

private extension String {
    func removeHexPrefix() -> String {
        if hasPrefix("0x") || hasPrefix("0X") {
            return String(dropFirst(2))
        }
        return self
    }
}
