//
//  PolymarketAddFundsFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketAddFundsFactory {
    private let services = PolymarketOnboardingServicesFactory.makeDefault()

    func makeInteractor(for userWalletModel: any UserWalletModel) -> PolymarketAddFundsInteractor {
        let walletId = userWalletModel.userWalletId.stringValue

        let configurationService = services.makeConfigurationService(
            walletId: walletId,
            store: InjectedValues[\.polymarketBuilderCodeStore]
        )

        let bridgeService = services.makeBridgeService(
            builderCode: { try await configurationService.builderCode() },
            supportedAssetsStore: InjectedValues[\.polymarketSupportedAssetsStore]
        )

        return PolymarketAddFundsInteractor(
            bridgeService: bridgeService,
            configurationService: configurationService,
            walletService: services.makeWalletService(),
            ownerAddressProvider: PolymarketOnboardingFactory().makeOwnerAddressProvider(for: userWalletModel),
            walletId: walletId
        )
    }
}
