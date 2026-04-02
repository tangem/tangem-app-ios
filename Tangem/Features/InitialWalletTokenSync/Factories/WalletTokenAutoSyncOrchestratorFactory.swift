//
//  WalletTokenAutoSyncOrchestratorFactory.swift
//  Tangem
//
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
        networkServiceFactory: WalletNetworkServiceFactoryProvider().factory
    )

    func makeOrchestrator() -> CommonWalletTokenAutoSyncOrchestrator {
        CommonWalletTokenAutoSyncOrchestrator(
            syncStateActor: sharedSyncStateActor,
            progressService: InjectedValues[\.walletTokenSyncProgressService],
            relayerFactory: makeRelayerFactory(
                configurationProvider: configurationProvider,
                coinsCatalogProvider: coinsCatalogProvider,
                tokenBalanceClient: InjectedValues[\.moralisTokenBalanceClient]
            )
        )
    }

    private func makeRelayerFactory(
        configurationProvider: InitialWalletTokenSyncConfigurationProvider,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider,
        tokenBalanceClient: MoralisTokenBalanceClient
    ) -> (Blockchain) -> (any WalletTokenAutoSyncRelayer)? {
        { blockchain in
            if configurationProvider.canHandle(blockchain) {
                return makeConfigurationRelayer(
                    configurationProvider: configurationProvider,
                    coinsCatalogProvider: coinsCatalogProvider
                )
            }

            if MoralisSupportedBlockchains.all.contains(blockchain) {
                return makeMoralisRelayer(
                    tokenBalanceClient: tokenBalanceClient,
                    coinsCatalogProvider: coinsCatalogProvider
                )
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
