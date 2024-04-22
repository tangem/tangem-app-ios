//
//  WalletDetailsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class WalletDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: WalletDetailsViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with userWalletModel: Options) {
        rootViewModel = WalletDetailsViewModel(userWalletModel: userWalletModel, coordinator: self)
    }
}

// MARK: - Options

extension WalletDetailsCoordinator {
    typealias Options = UserWalletModel
}

// MARK: - WalletDetailsRoutable

extension WalletDetailsCoordinator: WalletDetailsRoutable {}
