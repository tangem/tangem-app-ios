//
//  FeedPortfolioTokenRouter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

final class FeedPortfolioTokenRouter {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private weak var navigation: (any FeedNavigation)?

    private let popToRootAction: Action<PopToRootOptions>

    init(context: FeedContext) {
        navigation = context.navigation
        popToRootAction = context.popToRootAction
    }

    func open(_ walletModel: any WalletModel) {
        guard
            let userWalletModel = userWalletRepository.models[walletModel.userWalletId],
            let accountModel = walletModel.account
        else {
            return
        }

        let coordinator = TokenDetailsCoordinator(
            dismissAction: { [weak navigation] _ in navigation?.dismissPresented() },
            popToRootAction: popToRootAction
        )

        coordinator.start(
            with: .init(
                userWalletInfo: userWalletModel.userWalletInfo,
                keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                walletModelsManager: accountModel.walletModelsManager,
                userTokensManager: accountModel.userTokensManager,
                addressBookManager: userWalletModel.addressBookManager,
                walletModel: walletModel,
                presentSource: .markets
            )
        )
        navigation?.presentFullScreen(
            .portfolioToken(coordinator),
            zoomingFrom: .portfolioToken(walletID: walletModel.userWalletId, accountID: accountModel.id, tokenID: walletModel.id)
        )
    }
}
