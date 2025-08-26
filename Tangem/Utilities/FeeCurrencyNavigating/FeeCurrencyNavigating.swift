//
//  FeeCurrencyNavigating.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

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
        coordinator.start(with: .init(userWalletModel: userWalletModel, walletModel: model))

        tokenDetailsCoordinator = coordinator
    }

    func makeSendCoordinator() -> SendCoordinator {
        return SendCoordinator(
            dismissAction: makeSendCoordinatorDismissAction(),
            popToRootAction: makeSendCoordinatorPopToRootAction()
        )
    }

    func makeSendCoordinatorDismissAction() -> Action<SendCoordinator.DismissOptions?> {
        return { [weak self] dismissOptions in
            self?.sendCoordinator = nil

            switch dismissOptions {
            case .openFeeCurrency(let userWalletId, let feeTokenItem):
                guard let result = FeeCurrencyFinder().findFeeWalletModel(userWalletId: userWalletId, feeTokenItem: feeTokenItem) else {
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + Self.feeCurrencyNavigationDelay) {
                    self?.openFeeCurrency(for: result.feeWalletModel, userWalletModel: result.userWalletModel)
                }
            case .closeButtonTap, .none:
                break
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
