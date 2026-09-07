//
//  PolymarketOnboardingFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketOnboardingFactory {
    private let services = PolymarketOnboardingServicesFactory.makeDefault()

    func makeInteractor(for userWalletModel: any UserWalletModel) -> PolymarketOnboardingInteractor {
        CommonPolymarketOnboardingInteractor(
            userWalletId: userWalletModel.userWalletId,
            ownerAddressProvider: makeOwnerAddressProvider(for: userWalletModel),
            signer: CommonPolymarketOnboardingSigner(
                keysRepository: userWalletModel.keysRepository,
                signer: userWalletModel.signer
            ),
            credentialsRepository: CommonPolymarketCredentialsRepository(),
            walletService: services.makeWalletService(),
            relayerService: services.makeRelayerService(),
            clobService: services.makeCLOBService()
        )
    }
}

// MARK: - Owner address

extension PolymarketOnboardingFactory {
    func makeOwnerAddressProvider(for userWalletModel: any UserWalletModel) -> PolymarketOwnerAddressProviding {
        CommonPolymarketOwnerAddressProvider(
            keysRepository: userWalletModel.keysRepository,
            keysDerivingFactory: PolymarketKeysDeriving(provider: userWalletModel),
            areHDWalletsSupported: userWalletModel.config.hasFeature(.hdWallets)
        )
    }
}
