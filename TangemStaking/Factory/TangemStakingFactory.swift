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

    public func makeStakingManager(
        integrationId: String,
        wallet: StakingWallet,
        provider: StakingAPIProvider,
        analyticsLogger: StakingAnalyticsLogger
    ) -> StakingManager {
        CommonStakingManager(
            integrationId: integrationId,
            wallet: wallet,
            provider: provider,
            analyticsLogger: analyticsLogger
        )
    }

    public func makeStakingAPIProvider(
        credential: StakingAPICredential,
        configuration: URLSessionConfiguration,
        plugins: [PluginType],
        apiType: StakingAPIType = .prod
    ) -> StakingAPIProvider {
        let provider = TangemProvider<StakeKitTarget>(plugins: plugins, sessionConfiguration: configuration)
        let service = StakeKitStakingAPIService(provider: provider, credential: credential, apiType: apiType)
        let mapper = StakeKitMapper()
        return CommonStakingAPIProvider(service: service, mapper: mapper)
    }

    public func makePendingHashesSender(
        repository: StakingPendingHashesRepository,
        provider: StakingAPIProvider
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
