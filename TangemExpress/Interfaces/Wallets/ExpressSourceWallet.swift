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
}

public extension ExpressSourceWallet {
    var isFeeCurrency: Bool { currency == feeCurrency }
}
