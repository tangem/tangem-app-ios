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

class StakingDependenciesFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeStakingAPIProvider() -> StakingAPIProvider {
        let plugins: [PluginType] = [
            TangemNetworkLoggerPlugin(logOptions: .verbose),
        ]

        return TangemStakingFactory().makeStakingAPIProvider(
            credential: StakingAPICredential(apiKey: keysManager.stakeKitKey),
            configuration: .stakingConfiguration,
            plugins: plugins
        )
    }

    func makeStakingManager(integrationId: String, wallet: StakingWallet) -> StakingManager {
        TangemStakingFactory().makeStakingManager(
            integrationId: integrationId,
            wallet: wallet,
            provider: makeStakingAPIProvider(),
            analyticsLogger: CommonStakingAnalyticsLogger()
        )
    }

    func makePendingHashesSender() -> StakingPendingHashesSender {
        let repository = CommonStakingPendingHashesRepository()
        let provider = makeStakingAPIProvider()

        return TangemStakingFactory().makePendingHashesSender(
            repository: repository,
            provider: provider
        )
    }
}
