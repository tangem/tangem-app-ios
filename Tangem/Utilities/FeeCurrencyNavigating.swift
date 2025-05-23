//
//  FeeCurrencyNavigating.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// A helper that helps to perform the common navigation flow: open the `Token Details` screen for the fee currency.
protocol FeeCurrencyNavigating where Self: AnyObject, Self: CoordinatorObject {
    static var feeCurrencyNavigationDelay: TimeInterval { get }

    var tokenDetailsCoordinator: TokenDetailsCoordinator? { get set }
    var sendCoordinator: SendCoordinator? { get set }

    func openFeeCurrency(for model: any WalletModel, userWalletModel: UserWalletModel)
}

// MARK: - Default implementation

extension FeeCurrencyNavigating {
    static var feeCurrencyNavigationDelay: TimeInterval { 0.6 }

    func openFeeCurrency(for model: any WalletModel, userWalletModel: UserWalletModel) {
        let dismissAction: Action<Void> = { [weak self] _ in
            self?.tokenDetailsCoordinator = nil
        }

        let coordinator = TokenDetailsCoordinator(dismissAction: dismissAction)
        coordinator.start(
            with: .init(
                userWalletModel: userWalletModel,
                walletModel: model,
                userTokensManager: userWalletModel.userTokensManager
            )
        )

        tokenDetailsCoordinator = coordinator
    }

    func makeSendCoordinator() -> SendCoordinator {
        return SendCoordinator(
            dismissAction: makeSendCoordinatorDismissAction(),
            popToRootAction: makeSendCoordinatorPopToRootAction()
        )
    }
}

// MARK: - Private implementation

private extension FeeCurrencyNavigating {
    func makeSendCoordinatorDismissAction() -> Action<(walletModel: any WalletModel, userWalletModel: UserWalletModel)?> {
        return { [weak self] navigationInfo in
            self?.sendCoordinator = nil

            if let navigationInfo {
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.feeCurrencyNavigationDelay) {
                    self?.openFeeCurrency(for: navigationInfo.walletModel, userWalletModel: navigationInfo.userWalletModel)
                }
            }
        }
    }

    func makeSendCoordinatorPopToRootAction() -> Action<PopToRootOptions> {
        return { [weak self] options in
            self?.sendCoordinator = nil
            self?.popToRoot(with: options)
        }
    }
}
