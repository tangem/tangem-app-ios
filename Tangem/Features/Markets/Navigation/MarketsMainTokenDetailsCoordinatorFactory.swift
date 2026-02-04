//
//  MarketsMainTokenDetailsCoordinatorFactory.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsMainTokenDetailsCoordinatorFactory {
    /// Creates and starts `TokenDetailsCoordinator` for the given wallet model and user wallet model.
    /// - Parameters:
    ///   - walletModel: The wallet model to show details for
    ///   - userWalletModel: The user wallet model (context)
    ///   - dismissAction: Called when the coordinator is dismissed
    ///   - popToRootAction: Called when pop to root is requested (default: no-op)
    /// - Returns: The started coordinator, or `nil` if in accounts build and wallet has no account
    static func make(
        walletModel: any WalletModel,
        userWalletModel: any UserWalletModel,
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) -> TokenDetailsCoordinator? {
        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction, popToRootAction: popToRootAction)

        // [REDACTED_TODO_COMMENT]
        if FeatureProvider.isAvailable(.accounts) {
            guard let account = walletModel.account else {
                let message = "Inconsistent state: WalletModel '\(walletModel.name)' has no account in accounts-enabled build"
                AppLogger.error(error: message)
                assertionFailure(message)
                return nil
            }

            coordinator.start(
                with: .init(
                    userWalletInfo: userWalletModel.userWalletInfo,
                    keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                    walletModelsManager: account.walletModelsManager,
                    userTokensManager: account.userTokensManager,
                    walletModel: walletModel
                )
            )
        } else {
            coordinator.start(
                with: .init(
                    userWalletInfo: userWalletModel.userWalletInfo,
                    keysDerivingInteractor: userWalletModel.keysDerivingInteractor,
                    walletModelsManager: userWalletModel.walletModelsManager, // accounts_fixes_needed_none
                    userTokensManager: userWalletModel.userTokensManager, // accounts_fixes_needed_none
                    walletModel: walletModel
                )
            )
        }

        return coordinator
    }
}
