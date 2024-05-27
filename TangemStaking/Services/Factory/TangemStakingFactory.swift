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
        credential: StakingAPICredential = StakingAPICredential(apiKey: "ccf0a87a-3d6a-41d0-afa4-3dfc1a101335"),
        configuration: URLSessionConfiguration
    ) -> StakingAPIProvider {
        let plugins: [PluginType] = [
            TangemNetworkLoggerPlugin(configuration: .init(
                output: TangemNetworkLoggerPlugin.tangemSdkLoggerOutput,
                logOptions: .verbose
            )),
        ]
        let provider = MoyaProvider<StakekitTarget>(session: Session(configuration: configuration), plugins: plugins)
        let service = StakekitStakingAPIService(provider: .init(), credential: credential)
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
