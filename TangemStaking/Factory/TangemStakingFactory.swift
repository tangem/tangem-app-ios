//
//  TangemStakingFactory.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import BlockchainSdk

public struct TangemStakingFactory {
    public init() {}

    public func makeStakingAPIProvider(
        credential: StakingAPICredential,
        configuration: URLSessionConfiguration
    ) -> StakingAPIProvider {
        let plugins: [PluginType] = [
            TangemNetworkLoggerPlugin(configuration: .init(
                output: TangemNetworkLoggerPlugin.tangemSdkLoggerOutput,
                logOptions: .verbose
            )),
        ]
        let provider = MoyaProvider<StakekitTarget>(session: Session(configuration: configuration), plugins: plugins)
        let service = StakekitStakingAPIService(provider: provider, credential: credential)
        let mapper = StakekitMapper()
        return CommonStakingAPIProvider(service: service, mapper: mapper)
    }
}

// MARK: - Injected configurations and dependencies

public struct StakingAPICredential {
    public let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }
}
