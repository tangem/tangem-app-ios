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

    var operationType: ExpressOperationType { get }
    var supportedProvidersFilter: SupportedProvidersFilter { get }
}

public extension ExpressSourceWallet {
    var isFeeCurrency: Bool { currency == feeCurrency }
}

public enum SupportedProvidersFilter {
    public static let swap: SupportedProvidersFilter = .byTypes([.dex, .cex, .dexBridge])
    public static let onramp: SupportedProvidersFilter = .byTypes([.onramp])
    public static let cex: SupportedProvidersFilter = .byTypes([.cex])

    case byTypes([ExpressProviderType])
    case byDifferentAddressExchangeSupport
}
