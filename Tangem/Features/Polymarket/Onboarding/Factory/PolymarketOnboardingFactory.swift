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
        fastTrading: PolymarketFastTradingContext?,
        coordinator: PolymarketWelcomeRoutable
    ) -> PolymarketWelcomeViewModel {
        let hasExistingAccount = hasExistingAccount(for: userWalletModel)
        let onboardingFastTrading = hasExistingAccount ? nil : fastTrading.map { fastTrading in
            PolymarketSessionKeyFactory().makeOnboardingFastTrading(for: userWalletModel, service: fastTrading.service)
        }

        return PolymarketWelcomeViewModel(
            interactor: makeInteractor(for: userWalletModel, fastTrading: onboardingFastTrading),
            hasExistingAccount: hasExistingAccount,
            signingButtonType: SigningActionButtonViewTypeBuilder().build(config: userWalletModel.config),
            fastTrading: onboardingFastTrading,
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
            fastTrading: fastTrading,
            operationSlot: PolymarketSessionKeyFactory.isFastTradingAvailable() ? PolymarketWalletOperationSlot(userWalletId: userWalletModel.userWalletId) : nil
        )
    }
}

// MARK: - Owner address

extension PolymarketOnboardingFactory {
    func makeOwnerAddressProvider(for userWalletModel: any UserWalletModel) -> PolymarketOwnerAddressProviding {
        CommonPolymarketOwnerAddressProvider(keysRepository: userWalletModel.keysRepository)
    }
}
