//
//  FeeCurrencyNavigating.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct FeeCurrencyNavigatingDismissOption {
    let userWalletId: UserWalletId
    let tokenItem: TokenItem

    init(walletModel: any WalletModel) {
        userWalletId = walletModel.userWalletId
        tokenItem = walletModel.feeTokenItem
    }

    init(userWalletId: UserWalletId, tokenItem: TokenItem) {
        self.userWalletId = userWalletId
        self.tokenItem = tokenItem
    }
}

/// A helper that helps to perform the common navigation flow: open the `Token Details` screen for the fee currency.
protocol FeeCurrencyNavigating where Self: AnyObject, Self: CoordinatorObject {
    static var feeCurrencyNavigationDelay: TimeInterval { get }

    var tokenDetailsCoordinator: TokenDetailsCoordinator? { get set }

    func openFeeCurrency(for walletModel: any WalletModel, userWalletModel: UserWalletModel)
}

// MARK: - Default implementation

extension FeeCurrencyNavigating {
    static var feeCurrencyNavigationDelay: TimeInterval { 0.6 }

    func proceedFeeCurrencyNavigatingDismissOption(option: FeeCurrencyNavigatingDismissOption?) {
        guard let feeCurrencyOption = option else {
            return
        }

        let result = try? WalletModelFinder.findWalletModel(
            userWalletId: feeCurrencyOption.userWalletId,
            tokenItem: feeCurrencyOption.tokenItem
        )

        guard let result else {
            AppLogger.error(error: "FeeCurrency doesn't found for \(feeCurrencyOption.tokenItem.name)")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.feeCurrencyNavigationDelay) { [weak self] in
            self?.openFeeCurrency(for: result.walletModel, userWalletModel: result.userWalletModel)
        }
    }

    func openFeeCurrency(for walletModel: any WalletModel, userWalletModel: UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)

        // [REDACTED_TODO_COMMENT]
        if FeatureProvider.isAvailable(.accounts) {
            guard let account = walletModel.account else {
                let message = "Inconsistent state: WalletModel '\(walletModel.name)' has no account in accounts-enabled build"
                AppLogger.error(error: message)
                assertionFailure(message)
                return
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

        tokenDetailsCoordinator = coordinator
    }
}
