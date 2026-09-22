//
//  DeeplinkOverlayContext+TokenDetails.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension DeeplinkOverlayContext {
    /// The token details of a wallet model already in hand. Two links end up here: the token link, once the
    /// token list has caught up with it, and a Yield screen asking for the fee currency on its way out.
    func makeTokenDetailsOverlay(
        walletModel: any WalletModel,
        userWalletModel: UserWalletModel,
        pendingTransactionDetails: PendingTransactionDetails?,
        id: String? = nil
    ) -> OverlayView? {
        guard let account = walletModel.account else {
            let message = "Inconsistent state: WalletModel '\(walletModel.name)' has no account in accounts-enabled build"
            AppLogger.error(error: message)
            assertionFailure(message)
            return nil
        }

        let coordinator = coordinatorFactory.makeTokenDetailsCoordinator(dismissAction: { dismiss() })

        coordinator.start(
            with: .init(
                userWalletInfo: userWalletModel.userWalletInfo,
                keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                walletModelsManager: account.walletModelsManager,
                userTokensManager: account.userTokensManager,
                addressBookManager: userWalletModel.addressBookManager,
                walletModel: walletModel,
                pendingTransactionDetails: pendingTransactionDetails
            )
        )

        return sheet(embedInNavigationStack { TokenDetailsCoordinatorView(coordinator: coordinator) }, id: id)
    }
}
