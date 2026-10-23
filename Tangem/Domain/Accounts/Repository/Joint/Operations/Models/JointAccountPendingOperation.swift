//
//  JointAccountPendingOperation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

/// An unfinished operation of the account, with the wallet it is made through: what a screen shows of it, and what
/// this member can do about it.
struct JointAccountPendingOperation: Equatable {
    var tokenItem: TokenItem { wallet.tokenItem }
    var amount: Amount? { operationAmount() }
    var fee: Amount? { operationFee() }
    var destination: String { innerCallType.destination }

    let wallet: JointAccountWallet
    let operation: JointAccountOperation
    let innerCallType: SafeInnerCallType
    let feeTokenItem: TokenItem?

    init(
        wallet: JointAccountWallet,
        operation: JointAccountOperation,
        innerCallType: SafeInnerCallType,
        feeTokenItem: TokenItem?
    ) {
        self.wallet = wallet
        self.operation = operation
        self.innerCallType = innerCallType
        self.feeTokenItem = feeTokenItem
    }
}

// MARK: - Actions

extension JointAccountPendingOperation {
    /// Counts this member's signature towards the threshold.
    func sign() async throws {
        try await wallet.sign(operation)
    }

    /// Declines the operation, which the initiator's own answer ends outright.
    func reject() async throws {
        try await wallet.reject(operation)
    }
}

// MARK: - Private

private extension JointAccountPendingOperation {
    /// - Returns: `nil` for an amount too large to state as a `Decimal`, which is better shown as unknown than
    /// understated.
    func operationAmount() -> Amount? {
        guard let value = innerCallType.value.decimal else {
            return nil
        }

        return Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: value / tokenItem.decimalValue)
    }

    /// - Returns: `nil` for a fee in a token this wallet has not added, which it cannot word.
    func operationFee() -> Amount? {
        guard let feeTokenItem, let value = operation.safeTransaction.fee.decimal else {
            return nil
        }

        return Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value / feeTokenItem.decimalValue)
    }
}
