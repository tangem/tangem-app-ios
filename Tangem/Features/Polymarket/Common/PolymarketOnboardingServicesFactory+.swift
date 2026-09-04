//
//  PolymarketOnboardingServicesFactory+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemNetworkUtils
import TangemPolymarket

extension PolymarketOnboardingServicesFactory {
    static func makeDefault() -> PolymarketOnboardingServicesFactory {
        PolymarketOnboardingServicesFactory(
            networkConfiguration: TangemProviderConfiguration(logOptions: .verbose),
            environment: PolymarketBFFEnvironment.current
        )
    }

    static func makeDefaultBridgeService(
        walletId: String,
        builderCodeStore: PolymarketBuilderCodeStore = InjectedValues[\.polymarketBuilderCodeStore],
        supportedAssetsStore: PolymarketSupportedAssetsStore = InjectedValues[\.polymarketSupportedAssetsStore]
    ) -> PolymarketBridgeService {
        let factory = makeDefault()
        let configurationService = factory.makeConfigurationService(walletId: walletId, store: builderCodeStore)

        return factory.makeBridgeService(
            builderCode: { try await configurationService.builderCode() },
            supportedAssetsStore: supportedAssetsStore
        )
    }
}
