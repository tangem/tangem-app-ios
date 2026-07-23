//
//  PriceAlertsScreenCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import Foundation
import Combine
import TangemFoundation

final class PriceAlertsScreenCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: PriceAlertsScreenViewModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with userWalletModel: InputOptions) {
        rootViewModel = PriceAlertsScreenViewModel(
            userWalletModel: userWalletModel,
            coordinator: self
        )
    }
}

// MARK: - Options

extension PriceAlertsScreenCoordinator {
    typealias InputOptions = UserWalletModel
    typealias OutputOptions = Void
}

// MARK: - PriceAlertsScreenRoutable

extension PriceAlertsScreenCoordinator: PriceAlertsScreenRoutable {
    func openAppSettings() {
        UIApplication.openSystemSettings()
    }
}
