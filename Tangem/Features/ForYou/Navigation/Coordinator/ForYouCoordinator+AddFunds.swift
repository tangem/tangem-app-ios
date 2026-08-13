//
//  ForYouCoordinator+AddFunds.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

@MainActor
extension ForYouCoordinator {
    func openAddFunds(userWalletModels: [any UserWalletModel], preferredWalletId: UserWalletId?) {
        let coordinator = ActionButtonsBuyCoordinator(
            dismissAction: { [weak self] payload in
                self?.addFundsCoordinator = nil
                guard let payload, let account = payload.walletModel.account else { return }
                self?.openTokenDetails(
                    userWalletModel: payload.userWalletModel,
                    accountModel: account,
                    walletModel: payload.walletModel
                )
            }
        )
        coordinator.start(with: .init(
            userWalletModels: userWalletModels,
            preferredWalletId: preferredWalletId
        ))
        addFundsCoordinator = coordinator
    }
}

// MARK: - Bought-token details

private extension ForYouCoordinator {
    func openTokenDetails(
        userWalletModel: UserWalletModel,
        accountModel: any CryptoAccountModel,
        walletModel: any WalletModel
    ) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.portfolioTokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)

        coordinator.start(
            with: .init(
                userWalletInfo: userWalletModel.userWalletInfo,
                keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                walletModelsManager: accountModel.walletModelsManager,
                userTokensManager: accountModel.userTokensManager,
                walletModel: walletModel,
                presentSource: .markets
            )
        )

        portfolioTokenDetailsCoordinator = coordinator
    }
}
