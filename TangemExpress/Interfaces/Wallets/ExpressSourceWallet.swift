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
    public static let swap: SupportedProvidersFilter = .byTypes(ExpressConstants.swapProviderTypes)
    public static let onramp: SupportedProvidersFilter = .byTypes([.onramp])
    public static let cex: SupportedProvidersFilter = .byTypes([.cex])
    public static let yieldModuleDEXSwap: SupportedProvidersFilter = .yieldProviders(YieldProvidersFilter())

    case byTypes([ExpressProviderType])
    case yieldProviders(YieldProvidersFilter)
    case byDifferentAddressExchangeSupport

    public func isSupported(provider: ExpressProvider) -> Bool {
        switch self {
        case .byTypes(let types):
            return types.contains(provider.type)
        case .yieldProviders(let filter):
            return filter.isSupported(provider: provider)
        case .byDifferentAddressExchangeSupport:
            return !provider.exchangeOnlyWithinSingleAddress
        }
    }
}

/// Tokens in Yield mode are limited to all CEX providers and allow-listed DEX providers.
/// As such tokens require extra logic for support of new DEX providers (like Moonpay).
public struct YieldProvidersFilter {
    private let allowedDEXProviderIds: Set<ExpressProvider.Id>

    public init(allowedDEXProviderIds: Set<ExpressProvider.Id> = ExpressConstants.yieldModuleDEXProviderIds) {
        self.allowedDEXProviderIds = allowedDEXProviderIds
    }

    public func isSupported(provider: ExpressProvider) -> Bool {
        if provider.type.isCEX {
            return true
        }

        if provider.type.isDEX {
            return allowedDEXProviderIds.contains(provider.id)
        }

        return false
    }
}
