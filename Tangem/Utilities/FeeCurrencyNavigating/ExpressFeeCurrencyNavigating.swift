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
            self?.proceedFeeCurrencyNavigatingDismissOption(option: dismissOptions)
        }
    }

    func makeExpressCoordinatorPopToRootAction() -> Action<PopToRootOptions> {
        return { [weak self] options in
            self?.expressCoordinator = nil
            self?.popToRoot(with: options)
        }
    }
}
