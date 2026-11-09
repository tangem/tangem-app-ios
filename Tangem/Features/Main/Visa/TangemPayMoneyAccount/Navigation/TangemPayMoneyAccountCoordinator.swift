//
//  TangemPayMoneyAccountCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class TangemPayMoneyAccountCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private(set) var options: Options!

    var isTopUpPickerPresenting = false
    var isWithdrawHubPresenting = false
    var isYieldModePresenting = false

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options
    }
}

// MARK: - Options

extension TangemPayMoneyAccountCoordinator {
    struct Options {
        let userWalletModel: any UserWalletModel
    }
}

// MARK: - Route

extension TangemPayMoneyAccountCoordinator {
    enum Route: Hashable {}
}

// MARK: - Money Account Output

extension TangemPayMoneyAccountCoordinator {
    func handle(_ output: TangemPayMoneyAccountViewModel.Output) {
        switch output {
        case .topup: break
        case .withdraw: break
        }
    }
}
