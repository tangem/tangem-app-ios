//
//  ExpressSourceWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public protocol ExpressSourceWallet: ExpressDestinationWallet {
    var feeCurrency: ExpressWalletCurrency { get }
    var feeProvider: FeeProvider { get }
    var allowanceProvider: AllowanceProvider { get }
    var balanceProvider: BalanceProvider { get }

    /// Checks whether the given transaction size is acceptable for processing.
    /// This validation is specific to the Li.Fi provider and applies only to the Solana blockchain. (Now)
    ///
    /// - Parameter size: Transaction size in bytes.
    /// - Returns: `true` if the transaction size is supported, otherwise `false`.
    func canProcessTransaction(of transactionData: String) -> Bool
}

public extension ExpressSourceWallet {
    var isFeeCurrency: Bool { currency == feeCurrency }
}
