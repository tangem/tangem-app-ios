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
    var allowanceProvider: AllowanceProvider? { get }
    var balanceProvider: BalanceProvider { get }
    var analyticsLogger: AnalyticsLogger { get }

    var supportedProviders: [ExpressProviderType] { get }
}

public extension ExpressSourceWallet {
    var isFeeCurrency: Bool { currency == feeCurrency }
}
