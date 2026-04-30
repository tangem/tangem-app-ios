//
//  WalletTokenAutoSyncOrchestratorFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct WalletTokenAutoSyncOrchestratorFactory {
    private let sharedSyncStateActor = WalletTokenAutoSyncStateActor()

    private let coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider = CommonInitialWalletTokenSyncCoinsCatalogProvider(
        tangemApiService: InjectedValues[\.tangemApiService]
    )

    private let configurationProvider: InitialWalletTokenSyncConfigurationProvider = CommonInitialWalletTokenSyncConfigurationProvider(
        networkServiceFactory: WalletNetworkServiceFactoryProvider().factory,
        isSolanaScaledUIEnabled: FeatureProvider.isAvailable(.solanaScaledUIEnabled)
    )

    private let persister: WalletTokenAutoSyncPersister = CommonWalletTokenAutoSyncPersister()
    private let analyticsProvider: WalletTokenAutoSyncAnalyticsProvider = CommonWalletTokenAutoSyncAnalyticsService()

    func makeOrchestrator() -> CommonWalletTokenAutoSyncOrchestrator {
        CommonWalletTokenAutoSyncOrchestrator(
            syncStateActor: sharedSyncStateActor,
            progressService: InjectedValues[\.walletTokenSyncProgressService],
            persister: persister,
            relayerFactory: makeRelayerFactory(
                configurationProvider: configurationProvider,
                coinsCatalogProvider: coinsCatalogProvider,
                tokenBalanceClient: InjectedValues[\.moralisTokenBalanceClient]
            ),
            userWalletRepository: InjectedValues[\.userWalletRepository],
            apiListProvider: InjectedValues[\.apiListProvider],
            analyticsProvider: analyticsProvider
        )
    }

    private func makeRelayerFactory(
        configurationProvider: InitialWalletTokenSyncConfigurationProvider,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider,
        tokenBalanceClient: MoralisTokenBalanceClient
    ) -> (Blockchain) -> (any WalletTokenAutoSyncRelayer)? {
        // Cached per-type relayers shared across all supported blockchains
        // to avoid allocating a fresh instance for every network on each sync run.
        let moralisRelayer: any WalletTokenAutoSyncRelayer = makeMoralisRelayer(
            tokenBalanceClient: tokenBalanceClient,
            coinsCatalogProvider: coinsCatalogProvider
        )
        let configurationRelayer: any WalletTokenAutoSyncRelayer = makeConfigurationRelayer(
            configurationProvider: configurationProvider,
            coinsCatalogProvider: coinsCatalogProvider
        )

        return { blockchain in
            // Use Moralis first to obtain blockchain balances
            if MoralisSupportedBlockchains.all.contains(blockchain) {
                return moralisRelayer
            }

            if configurationProvider.canHandle(blockchain) {
                return configurationRelayer
            }

            return nil
        }
    }

    private func makeConfigurationRelayer(
        configurationProvider: InitialWalletTokenSyncConfigurationProvider,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider
    ) -> WalletTokenAutoSyncRelayer {
        ConfigurationWalletTokenAutoSyncRelayer(
            configurationProvider: configurationProvider,
            coinsCatalogProvider: coinsCatalogProvider
        )
    }

    private func makeMoralisRelayer(
        tokenBalanceClient: MoralisTokenBalanceClient,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider
    ) -> WalletTokenAutoSyncRelayer {
        MoralisWalletTokenAutoSyncRelayer(
            tokenBalanceClient: tokenBalanceClient,
            coinsCatalogProvider: coinsCatalogProvider
        )
    }
}
