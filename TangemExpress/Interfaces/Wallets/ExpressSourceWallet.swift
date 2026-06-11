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
    var walletInfo: ExpressWalletInfo { get }
    var allowanceProvider: AllowanceProvider? { get }
    var yieldModuleTransactionHelper: YieldModuleTransactionHelper? { get }
    var balanceProvider: BalanceProvider { get }
    var analyticsLogger: AnalyticsLogger { get }
    var providerTransactionValidator: ExpressProviderTransactionValidator { get }

    var operationType: ExpressOperationType { get }
    var supportedProvidersFilter: SupportedProvidersFilter { get }

    var expressFeeProviderFactory: ExpressFeeProviderFactory { get }
}

public protocol YieldModuleTransactionHelper {
    /// Used as `fromAddress` for DEX providers instead of the default wallet address when yield mode is active.
    var yieldContractAddress: String? { get }

    func prepareForYieldModuleDEXSwap(provider: ExpressProvider) async throws
    func yieldModuleDEXSwapData(data: ExpressTransactionData, provider: ExpressProvider, spender: String) async throws -> ExpressTransactionData
}

public enum SupportedProvidersFilter {
    public static let swap: SupportedProvidersFilter = .byTypes([.dex, .cex, .dexBridge])
    public static let onramp: SupportedProvidersFilter = .byTypes([.onramp])
    public static let cex: SupportedProvidersFilter = .byTypes([.cex])

    case byTypes([ExpressProviderType])
    case byDifferentAddressExchangeSupport
}
