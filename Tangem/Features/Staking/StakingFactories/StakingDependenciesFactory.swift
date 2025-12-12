//
//  StakingDependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemNetworkUtils
import BlockchainSdk
import Moya
import TangemFoundation

class StakingDependenciesFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeStakeKitAPIProvider() -> StakeKitAPIProvider {
        let plugins: [PluginType] = [
            TangemNetworkLoggerPlugin(logOptions: .verbose),
        ]

        return TangemStakingFactory().makeStakeKitAPIProvider(
            credential: StakingAPICredential(apiKey: keysManager.stakeKitKey),
            configuration: .stakingConfiguration,
            plugins: plugins,
            apiType: FeatureStorage.instance.stakeKitAPIType
        )
    }

    func makeP2PAPIProvider() -> P2PAPIProvider {
        let plugins: [PluginType] = [
            TangemNetworkLoggerPlugin(logOptions: .verbose),
        ]

        let network: P2PNetwork
        let apiKey: String
        if AppEnvironment.current.isTestnet {
            network = .hoodi
            apiKey = keysManager.p2pApiKeys.hoodi
        } else {
            network = .mainnet
            apiKey = keysManager.p2pApiKeys.mainnet
        }

        return TangemStakingFactory().makeP2PAPIProvider(
            credential: StakingAPICredential(apiKey: apiKey),
            configuration: .stakingConfiguration,
            plugins: plugins,
            network: network,
        )
    }

    func makeStakingManager(integrationId: String, wallet: StakingWallet) -> StakingManager {
        switch (wallet.item.network, wallet.item.contractAddress) {
        case (.ethereum, .none):
            TangemStakingFactory().makeP2PStakingManager(
                wallet: wallet,
                provider: makeP2PAPIProvider(),
                stateRepository: CommonStakingManagerStateRepository(
                    stakingWallet: wallet,
                    storage: CachesDirectoryStorage(file: .cachedStakingManagerState)
                ),
                analyticsLogger: CommonStakingAnalyticsLogger()
            )
        default:
            TangemStakingFactory().makeStakeKitStakingManager(
                integrationId: integrationId,
                wallet: wallet,
                provider: makeStakeKitAPIProvider(),
                stateRepository: CommonStakingManagerStateRepository(
                    stakingWallet: wallet,
                    storage: CachesDirectoryStorage(file: .cachedStakingManagerState)
                ),
                analyticsLogger: CommonStakingAnalyticsLogger()
            )
        }
    }

    func makePendingHashesSender() -> StakingPendingHashesSender {
        let repository = CommonStakingPendingHashesRepository()
        let provider = makeStakeKitAPIProvider()

        return TangemStakingFactory().makePendingHashesSender(
            repository: repository,
            provider: provider
        )
    }
}
