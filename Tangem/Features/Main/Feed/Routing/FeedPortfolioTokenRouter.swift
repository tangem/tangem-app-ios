//
//  FeedPortfolioTokenRouter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

final class FeedPortfolioTokenRouter {
    private let ownerResolver = WalletModelOwnerResolver()

    private weak var navigation: (any FeedNavigation)?

    private let popToRootAction: Action<PopToRootOptions>

    init(context: FeedContext) {
        navigation = context.navigation
        popToRootAction = context.popToRootAction
    }

    func open(_ walletModel: any WalletModel) {
        guard let owner = ownerResolver.resolve(walletModel) else {
            return
        }

        let coordinator = makeCoordinator(
            for: owner,
            dismissAction: { [weak navigation] _ in navigation?.dismissPresented() }
        )

        navigation?.presentFullScreen(
            .portfolioToken(coordinator),
            zoomingFrom: .portfolioToken(walletID: owner.walletModel.userWalletId, accountID: owner.account.id, tokenID: owner.walletModel.id)
        )
    }

    func push(_ walletModel: any WalletModel) {
        guard let owner = ownerResolver.resolve(walletModel) else {
            return
        }

        let coordinator = makeCoordinator(
            for: owner,
            dismissAction: { [weak navigation] _ in navigation?.pop() }
        )

        navigation?.push(.portfolioToken(coordinator))
    }
}

// MARK: - Private

private extension FeedPortfolioTokenRouter {
    func makeCoordinator(
        for owner: WalletModelOwner,
        dismissAction: @escaping Action<Void>
    ) -> TokenDetailsCoordinator {
        let coordinator = TokenDetailsCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(
            with: .init(
                userWalletInfo: owner.userWalletModel.userWalletInfo,
                keysDerivingInteractor: owner.userWalletModel.keysDerivingInteractor,
                walletModelsManager: owner.account.walletModelsManager,
                userTokensManager: owner.account.userTokensManager,
                addressBookManager: owner.userWalletModel.addressBookManager,
                walletModel: owner.walletModel,
                presentSource: .markets
            )
        )

        return coordinator
    }
}
