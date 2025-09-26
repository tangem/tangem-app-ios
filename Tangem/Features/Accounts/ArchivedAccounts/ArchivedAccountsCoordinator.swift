//
//  ArchivedAccountsCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUIUtils
import TangemUI
import TangemLocalization
import SwiftUI

final class ArchivedAccountsCoordinator: CoordinatorObject {
    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private var options: Options?

    // MARK: - Root view model

    @Published private(set) var rootViewModel: ArchivedAccountsViewModel?

    // MARK: - Alerts

    @Published var alertBinder: AlertBinder?

    // MARK: - Confirmation dialog

    @Published var recoverAccountDialogPresented = false
    private(set) var recoverAction: (() -> Void)?

    init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = ArchivedAccountsViewModel(accountModelsManager: options.accountModelsManager, coordinator: self)
    }
}

// MARK: - Options

extension ArchivedAccountsCoordinator {
    struct Options {
        let accountModelsManager: AccountModelsManager
    }
}

// MARK: - RecoverableAccountRoutable

extension ArchivedAccountsCoordinator: RecoverableAccountRoutable {
    func recoverAccount(action: @escaping () throws -> Void) {
        recoverAccountDialogPresented = true
        recoverAction = { [weak self] in
            do {
                try action()

                self?.dismiss()

                Toast(view: SuccessToast(text: Localization.accountRecoverSuccessMessage))
                    .present(layout: .top(padding: 24), type: .temporary(interval: 4))
            } catch {
                self?.alertBinder = AlertBuilder.makeAlert(
                    title: "Can't recover account",
                    message: "You have already exceeded the limit of 20 active accounts. Archive one to recover",
                    primaryButton: .default(Text(Localization.commonGotIt))
                )
            }
        }
    }
}
