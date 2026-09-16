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

    init(wallet: JointAccountWallet, operation: JointAccountOperation, innerCallType: SafeInnerCallType) {
        self.wallet = wallet
        self.operation = operation
        self.innerCallType = innerCallType
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

    /// - Returns: `nil` for a fee in a token, which this version does not quote and so cannot word.
    func operationFee() -> Amount? {
        let safeTransaction = operation.safeTransaction

        guard let value = safeTransaction.fee.decimal else {
            return nil
        }

        if safeTransaction.gasToken.caseInsensitiveEquals(to: SafeGasToken.coinGasTokenRawValue) {
            return Amount(with: tokenItem.blockchain, value: value / tokenItem.blockchain.decimalValue)
        }

        assertionFailure("A joint account operation paying its fee in a token is not supported yet")
        JointAccountsLogger.warning("An unfinished operation of a joint account pays its fee in a token")
        return nil
    }
}
