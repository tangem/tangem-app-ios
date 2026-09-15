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

/// An unfinished operation of the account, with the wallet it is made through.
struct JointAccountPendingOperation: Equatable {
    let wallet: JointAccountWallet
    let operation: JointAccountOperation
    let innerCallType: SafeInnerCallType
}

// MARK: - Convenience

extension JointAccountPendingOperation {
    var tokenItem: TokenItem {
        wallet.tokenItem
    }

    /// What the transfer moves, in the units the token is quoted in; an amount too large to state as a `Decimal` has
    /// none to show rather than one that understates it.
    var amount: Amount? {
        guard let value = innerCallType.value.decimal else {
            return nil
        }

        return Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: value / tokenItem.decimalValue)
    }

    var destination: String {
        innerCallType.destination
    }

    /// What the account pays for the network at most, in the coin; a fee in a token is not expected yet, so it has no
    /// amount to show.
    var fee: Amount? {
        let safeTransaction = operation.safeTransaction

        guard let value = safeTransaction.fee.decimal else {
            return nil
        }

        if safeTransaction.gasToken.caseInsensitiveEquals(to: SafeGasToken.coinGasTokenRawValue) {
            return Amount(with: tokenItem.blockchain, value: value / tokenItem.blockchain.decimalValue)
        }

        // This version quotes no fee in a token, so an operation paying one was made elsewhere; its fee is left unshown
        // rather than misstated in the coin
        assertionFailure("A joint account operation paying its fee in a token is not supported yet")
        JointAccountsLogger.warning("An unfinished operation of a joint account pays its fee in a token, which this version cannot show")
        return nil
    }
}
