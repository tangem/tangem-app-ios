//
//  NotificationSettingsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import Foundation
import Combine
import TangemFoundation

final class NotificationSettingsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Root view model

    @Published private(set) var rootViewModel: NotificationSettingsViewModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with userWalletModel: InputOptions) {
        rootViewModel = NotificationSettingsViewModel(
            userWalletModel: userWalletModel,
            coordinator: self
        )
    }
}

// MARK: - Options

extension NotificationSettingsCoordinator {
    typealias InputOptions = UserWalletModel
    typealias OutputOptions = Void
}

// MARK: - NotificationSettingsRoutable

extension NotificationSettingsCoordinator: NotificationSettingsRoutable {
    func openAppSettings() {
        UIApplication.openSystemSettings()
    }

    func onAlertDismiss() {
        // No-op: required by `NotificationSettingsRoutable`. Reserved for future
        // pending-navigation handling, mirroring `UserWalletSettingsCoordinator`.
    }
}

// MARK: - TransactionNotificationsRowToggleRoutable

extension NotificationSettingsCoordinator: TransactionNotificationsRowToggleRoutable {
    func openTransactionNotifications() {
        let viewModel = TransactionNotificationsModalViewModel(coordinator: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - TransactionNotificationsModalRoutable

extension NotificationSettingsCoordinator: TransactionNotificationsModalRoutable {
    func dismissTransactionNotifications() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
