//
//  PolymarketAccountFundsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketAccountFundsFactory {
    private let services = PolymarketOnboardingServicesFactory.makeDefault()

    func makeInteractor(for userWalletModel: any UserWalletModel) -> PolymarketAccountFundsInteractor {
        let walletId = userWalletModel.userWalletId.stringValue

        let configurationService = services.makeConfigurationService(
            walletId: walletId,
            store: InjectedValues[\.polymarketBuilderCodeStore]
        )

        let bridgeService = services.makeBridgeService()

        return PolymarketAccountFundsInteractor(
            bridgeService: bridgeService,
            configurationService: configurationService,
            walletService: services.makeWalletService(walletId: walletId),
            ownerAddressProvider: PolymarketOnboardingFactory().makeOwnerAddressProvider(for: userWalletModel)
        )
    }
}
