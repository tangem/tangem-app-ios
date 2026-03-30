//
//  WalletTokenAutoSyncOrchestratorFactory.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

final class WalletTokenAutoSyncOrchestratorFactory {
    private let sharedSyncStateActor = WalletTokenAutoSyncStateActor()
    private let addressResolver = WalletAddressResolver()
    private let coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider = CommonInitialWalletTokenSyncCoinsCatalogProvider(
        tangemApiService: InjectedValues[\.tangemApiService]
    )

    func makeOrchestrator() -> CommonWalletTokenAutoSyncOrchestrator {
        CommonWalletTokenAutoSyncOrchestrator(
            syncStateActor: sharedSyncStateActor,
            progressService: InjectedValues[\.walletTokenSyncProgressService],
            relayerFactory: makeRelayerFactory(
                addressResolver: addressResolver,
                coinsCatalogProvider: coinsCatalogProvider,
                tokenBalanceClient: InjectedValues[\.moralisTokenBalanceClient]
            )
        )
    }

    private func makeRelayerFactory(
        addressResolver: WalletAddressResolver,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider,
        tokenBalanceClient: MoralisTokenBalanceClient
    ) -> (Blockchain) -> (any WalletTokenAutoSyncRelayer)? {
        { [weak self] blockchain in
            // [REDACTED_TODO_COMMENT]
            // [REDACTED_TODO_COMMENT]

            guard let self else {
                return nil
            }

            if MoralisSupportedBlockchains.all.contains(blockchain) {
                return makeMoralisRelayer(
                    addressResolver: addressResolver,
                    tokenBalanceClient: tokenBalanceClient,
                    coinsCatalogProvider: coinsCatalogProvider
                )
            }

            return nil
        }
    }

    private func makeMoralisRelayer(
        addressResolver: WalletAddressResolver,
        tokenBalanceClient: MoralisTokenBalanceClient,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider
    ) -> WalletTokenAutoSyncRelayer {
        MoralisWalletTokenAutoSyncRelayer(
            addressResolver: addressResolver,
            tokenBalanceClient: tokenBalanceClient,
            coinsCatalogProvider: coinsCatalogProvider
        )
    }
}
