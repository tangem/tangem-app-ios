//
//  PolymarketOnboardingFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemUI

struct PolymarketOnboardingFactory {
    private let services = PolymarketOnboardingServicesFactory.makeDefault()
    private let presenceStore: PolymarketAccountPresenceStore = AppSettings.shared

    func makeWelcomeViewModel(
        for userWalletModel: any UserWalletModel,
        coordinator: PolymarketWelcomeRoutable
    ) -> PolymarketWelcomeViewModel {
        let hasExistingAccount = hasExistingAccount(for: userWalletModel)
        let fastTrading = hasExistingAccount ? nil : PolymarketSessionKeyFactory().makeOnboardingFastTrading(for: userWalletModel)

        return PolymarketWelcomeViewModel(
            interactor: makeInteractor(for: userWalletModel, fastTrading: fastTrading),
            hasExistingAccount: hasExistingAccount,
            signingButtonType: SigningActionButtonViewTypeBuilder().build(config: userWalletModel.config),
            fastTrading: fastTrading,
            coordinator: coordinator
        )
    }

    private func hasExistingAccount(for userWalletModel: any UserWalletModel) -> Bool {
        let state = AccountModelsAggregator(.polymarket).model(from: userWalletModel.accountModelsManager)?.state

        return state == .syncNeeded || presenceStore.hasAccount(userWalletId: userWalletModel.userWalletId)
    }

    func makeInteractor(
        for userWalletModel: any UserWalletModel,
        fastTrading: PolymarketOnboardingFastTrading?
    ) -> PolymarketOnboardingInteractor {
        CommonPolymarketOnboardingInteractor(
            userWalletId: userWalletModel.userWalletId,
            hasExistingAccount: { hasExistingAccount(for: userWalletModel) },
            ownerAddressProvider: makeOwnerAddressProvider(for: userWalletModel),
            ownerKeySession: userWalletModel.polymarketOwnerKeySession,
            signer: CommonPolymarketOnboardingSigner(
                keysRepository: userWalletModel.keysRepository,
                signer: userWalletModel.signer
            ),
            credentialsRepository: CommonPolymarketCredentialsRepository(),
            geoblockService: services.makeGeoblockService(),
            walletService: services.makeWalletService(walletId: userWalletModel.userWalletId.stringValue),
            relayerService: services.makeRelayerService(),
            clobService: services.makeCLOBService(),
            serverClock: InjectedValues[\.polymarketServerClock],
            fastTrading: fastTrading
        )
    }
}

// MARK: - Owner address

extension PolymarketOnboardingFactory {
    func makeOwnerAddressProvider(for userWalletModel: any UserWalletModel) -> PolymarketOwnerAddressProviding {
        CommonPolymarketOwnerAddressProvider(keysRepository: userWalletModel.keysRepository)
    }
}
