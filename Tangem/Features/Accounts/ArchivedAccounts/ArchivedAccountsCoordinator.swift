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

    let dismissAction: Action<AccountOperationResult>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: ArchivedAccountsViewModel?

    init(
        dismissAction: @escaping Action<AccountOperationResult>,
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
    func close(with accountOperationResult: AccountOperationResult) {
        dismiss(with: accountOperationResult)
    }
}
