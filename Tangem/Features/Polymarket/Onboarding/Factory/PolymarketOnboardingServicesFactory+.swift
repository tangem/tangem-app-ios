//
//  PolymarketOnboardingServicesFactory+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
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

// MARK: - CLOB services by credentials

extension PolymarketOnboardingServicesFactory {
    func makeOwnerCLOBService(userWalletId: UserWalletId) -> PolymarketCLOBService {
        makeCLOBService(walletId: userWalletId.stringValue)
    }

    func makeSessionKeyCLOBService() -> PolymarketCLOBService {
        makeCLOBService(walletId: nil)
    }
}
