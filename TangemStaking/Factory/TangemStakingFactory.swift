//
//  TangemStakingFactory.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemNetworkUtils

public struct TangemStakingFactory {
    public init() {}

    public func makeStakeKitStakingManager(
        integrationId: String,
        wallet: StakingWallet,
        provider: StakeKitAPIProvider,
        yieldInfoProvider: StakingYieldInfoProvider,
        stateRepository: StakingManagerStateRepository,
        analyticsLogger: StakingAnalyticsLogger
    ) -> StakingManager {
        StakeKitStakingManager(
            integrationId: integrationId,
            wallet: wallet,
            apiProvider: provider,
            yieldInfoProvider: yieldInfoProvider,
            stateRepository: stateRepository,
            analyticsLogger: analyticsLogger
        )
    }

    public func makeP2PStakingManager(
        integrationId: String,
        wallet: StakingWallet,
        provider: P2PAPIProvider,
        yieldInfoProvider: StakingYieldInfoProvider,
        stateRepository: StakingManagerStateRepository,
        analyticsLogger: StakingAnalyticsLogger
    ) -> StakingManager {
        P2PStakingManager(
            integrationId: integrationId,
            wallet: wallet,
            apiProvider: provider,
            yieldInfoProvider: yieldInfoProvider,
            stateRepository: stateRepository,
            analyticsLogger: analyticsLogger
        )
    }

    public func makeStakeKitAPIProvider(
        credential: StakingAPICredential,
        configuration: URLSessionConfiguration,
        plugins: [PluginType],
        apiType: StakeKitAPIType = .prod
    ) -> StakeKitAPIProvider {
        let provider = TangemProvider<StakeKitTarget>(plugins: plugins, sessionConfiguration: configuration)
        let service = CommonStakeKitStakingAPIService(provider: provider, credential: credential, apiType: apiType)
        let mapper = StakeKitMapper()
        return CommonStakeKitAPIProvider(service: service, mapper: mapper)
    }

    public func makeP2PAPIProvider(
        credential: StakingAPICredential,
        configuration: URLSessionConfiguration,
        plugins: [PluginType],
        network: P2PNetwork
    ) -> P2PAPIProvider {
        let provider = TangemProvider<P2PTarget>(plugins: plugins, sessionConfiguration: configuration)
        let service = CommonP2PStakingAPIService(
            provider: provider,
            credential: credential,
            network: network
        )
        let mapper = P2PMapper()
        return CommonP2PAPIProvider(service: service, mapper: mapper)
    }

    public func makePendingHashesSender(
        repository: StakingPendingHashesRepository,
        provider: StakeKitAPIProvider
    ) -> StakingPendingHashesSender {
        CommonStakingPendingHashesSender(repository: repository, provider: provider)
    }
}

// MARK: - Injected configurations and dependencies

public struct StakingAPICredential {
    public let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }
}
