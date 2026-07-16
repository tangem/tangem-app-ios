//
//  BinanceInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct BinanceInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard case .binance = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let networkService = BinanceNetworkService(isTestNet: blockchain.isTestnet)

        do {
            let response = try await networkService.getInfo(address: address).async()
            let coinSymbol = blockchain.currencySymbol
            let nativeBalance = response.balances[coinSymbol] ?? 0

            let tokenBalances = response.balances
                .filter { $0.key != coinSymbol }
                .map { WalletAssetsDiscoveryTokenBalance(contractAddress: $0.key, balance: $0.value) }

            return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: nativeBalance, tokens: tokenBalances)
        } catch {
            if case BlockchainSdkError.noAccount = error {
                return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: 0, tokens: [])
            }

            throw error
        }
    }
}
