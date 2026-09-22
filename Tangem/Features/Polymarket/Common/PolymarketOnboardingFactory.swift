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
    private let presenceStore: PolymarketAccountPresenceStore = AppSettings.shared

    func makeWelcomeViewModel(
        for userWalletModel: any UserWalletModel,
        coordinator: PolymarketWelcomeRoutable
    ) -> PolymarketWelcomeViewModel {
        PolymarketWelcomeViewModel(
            interactor: makeInteractor(for: userWalletModel),
            hasExistingAccount: hasExistingAccount(for: userWalletModel),
            coordinator: coordinator
        )
    }

    private func hasExistingAccount(for userWalletModel: any UserWalletModel) -> Bool {
        let state = AccountModelsAggregator(.polymarket).model(from: userWalletModel.accountModelsManager)?.state

        return state == .syncNeeded || presenceStore.hasAccount(userWalletId: userWalletModel.userWalletId)
    }

    func makeInteractor(for userWalletModel: any UserWalletModel) -> PolymarketOnboardingInteractor {
        CommonPolymarketOnboardingInteractor(
            userWalletId: userWalletModel.userWalletId,
            ownerAddressProvider: makeOwnerAddressProvider(for: userWalletModel),
            signer: CommonPolymarketOnboardingSigner(
                keysRepository: userWalletModel.keysRepository,
                signer: userWalletModel.signer
            ),
            credentialsRepository: CommonPolymarketCredentialsRepository(),
            geoblockService: services.makeGeoblockService(),
            walletService: services.makeWalletService(walletId: userWalletModel.userWalletId.stringValue),
            relayerService: services.makeRelayerService(),
            clobService: services.makeCLOBService(),
            serverClock: InjectedValues[\.polymarketServerClock]
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
