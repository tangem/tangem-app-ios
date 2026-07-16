//
//  WalletAssetsDiscoveryOrchestratorFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

final class WalletAssetsDiscoveryOrchestratorFactory {
    private let sharedSyncStateActor = WalletAssetsDiscoveryStateActor()

    private let coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider = CommonInitialWalletTokenSyncCoinsCatalogProvider(
        tangemApiService: InjectedValues[\.tangemApiService]
    )

    private let networkServiceFactoryProvider = WalletNetworkServiceFactoryProvider()

    private lazy var configurationProvider: WalletAssetsDiscoveryBalanceProvider = {
        let provider = networkServiceFactoryProvider

        return CommonInitialWalletTokenSyncConfigurationProvider(
            networkServiceFactory: provider.factory
        )
    }()

    private let persister: WalletAssetsDiscoveryPersister = CommonWalletAssetsDiscoveryPersister()
    private let analyticsProvider: WalletAssetsDiscoveryAnalyticsProvider = CommonWalletAssetsDiscoveryAnalyticsService()

    func makeOrchestrator() -> CommonWalletAssetsDiscoveryOrchestrator {
        CommonWalletAssetsDiscoveryOrchestrator(
            syncStateActor: sharedSyncStateActor,
            progressService: InjectedValues[\.walletAssetsDiscoveryProgressService],
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
        configurationProvider: WalletAssetsDiscoveryBalanceProvider,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider,
        tokenBalanceClient: MoralisTokenBalanceClient
    ) -> (Blockchain) -> (any WalletAssetsDiscoveryRelayer)? {
        // Cached per-type relayers shared across all supported blockchains
        // to avoid allocating a fresh instance for every network on each sync run.
        let moralisRelayer: any WalletAssetsDiscoveryRelayer = makeMoralisRelayer(
            tokenBalanceClient: tokenBalanceClient,
            coinsCatalogProvider: coinsCatalogProvider
        )
        let configurationRelayer: any WalletAssetsDiscoveryRelayer = makeConfigurationRelayer(
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
        configurationProvider: WalletAssetsDiscoveryBalanceProvider,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider
    ) -> WalletAssetsDiscoveryRelayer {
        ConfigurationWalletAssetsDiscoveryRelayer(
            configurationProvider: configurationProvider,
            coinsCatalogProvider: coinsCatalogProvider
        )
    }

    private func makeMoralisRelayer(
        tokenBalanceClient: MoralisTokenBalanceClient,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider
    ) -> WalletAssetsDiscoveryRelayer {
        MoralisWalletAssetsDiscoveryRelayer(
            tokenBalanceClient: tokenBalanceClient,
            coinsCatalogProvider: coinsCatalogProvider
        )
    }
}
