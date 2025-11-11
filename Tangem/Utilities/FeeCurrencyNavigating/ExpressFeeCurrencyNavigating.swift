//
//  ExpressFeeCurrencyNavigating.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - ExpressFeeCurrencyNavigating

protocol ExpressFeeCurrencyNavigating: FeeCurrencyNavigating {
    var expressCoordinator: ExpressCoordinator? { get set }
}

// MARK: - Default implementation

extension ExpressFeeCurrencyNavigating {
    func makeExpressCoordinator(factory: any ExpressModulesFactory) -> ExpressCoordinator {
        return ExpressCoordinator(
            factory: factory,
            dismissAction: makeExpressCoordinatorDismissAction(),
            popToRootAction: makeExpressCoordinatorPopToRootAction()
        )
    }

    func makeExpressCoordinatorDismissAction() -> ExpressCoordinator.DismissAction {
        return { [weak self] dismissOptions in
            self?.expressCoordinator = nil

            switch dismissOptions {
            case .openFeeCurrency(let userWalletId, let feeTokenItem):
                guard let result = FeeCurrencyFinder().findFeeWalletModel(userWalletId: userWalletId, feeTokenItem: feeTokenItem) else {
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + Self.feeCurrencyNavigationDelay) {
                    self?.openFeeCurrency(for: result.feeWalletModel, userWalletModel: result.userWalletModel)
                }
            case .none:
                break
            }
        }
    }

    func makeExpressCoordinatorPopToRootAction() -> Action<PopToRootOptions> {
        return { [weak self] options in
            self?.expressCoordinator = nil
            self?.popToRoot(with: options)
        }
    }
}
