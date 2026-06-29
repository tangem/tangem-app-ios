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
import TangemFoundation

class StakingDependenciesFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.stakingYieldInfoProvider) private var stakingYieldInfoProvider: StakingYieldInfoProvider
    @Injected(\.p2pBatchBalancesService) private var p2pBatchBalancesService: P2PBatchBalancesService

    @Injected(\.stakingTargetAmountLimitProvider) var targetAmountLimitProvider: StakingTargetAmountLimitProvider

    func makeStakeKitAPIProvider() -> StakeKitAPIProvider {
        return TangemStakingFactory().makeStakeKitAPIProvider(
            credential: StakingAPICredential(apiKey: keysManager.stakeKitKey),
            configuration: .stakingConfiguration,
            apiType: FeatureStorage.instance.stakeKitAPIType
        )
    }

    func makeP2PAPIProvider() -> P2PAPIProvider {
        let config = p2pConfig()
        return TangemStakingFactory().makeP2PAPIProvider(
            credential: StakingAPICredential(apiKey: config.apiKey),
            configuration: .stakingConfiguration,
            network: config.network,
        )
    }

    func makeP2PBatchBalancesService() -> P2PBatchBalancesService {
        let config = p2pConfig()
        return TangemStakingFactory().makeP2PBatchBalancesService(
            credential: StakingAPICredential(apiKey: config.apiKey),
            configuration: .stakingConfiguration,
            network: config.network,
            addressProvider: CommonP2PDelegatorAddressProvider(),
            yieldInfoProvider: stakingYieldInfoProvider
        )
    }

    private func p2pConfig() -> (network: P2PNetwork, apiKey: String) {
        if AppEnvironment.current.isTestnet {
            return (.hoodi, keysManager.p2pApiKeys.hoodi)
        }
        return (.mainnet, keysManager.p2pApiKeys.mainnet)
    }

    func makeStakingManager(integrationId: String, wallet: StakingWallet) -> StakingManager {
        switch (wallet.item.network, wallet.item.contractAddress) {
        case (.ethereum, .none):
            TangemStakingFactory().makeP2PStakingManager(
                integrationId: integrationId,
                wallet: wallet,
                provider: makeP2PAPIProvider(),
                batchBalancesService: p2pBatchBalancesService,
                yieldInfoProvider: stakingYieldInfoProvider,
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
                yieldInfoProvider: stakingYieldInfoProvider,
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
