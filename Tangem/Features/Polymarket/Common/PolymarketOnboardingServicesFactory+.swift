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
            networkConfiguration: TangemProviderConfiguration(
                logOptions: .verbose,
                urlSessionConfiguration: .polymarketConfiguration
            ),
            environment: PolymarketBFFEnvironment.current,
            serverClock: InjectedValues[\.polymarketServerClock],
            unauthorizedObserver: InjectedValues[\.polymarketUnauthorizedEvents]
        )
    }
}
