//
//  JointAccountFormViewCreator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization

struct JointAccountFormViewCreator {
    private let accountModelsManager: AccountModelsManager
    private let creationHelper: JointAccountCreationHelper

    init(accountModelsManager: AccountModelsManager, creationHelper: JointAccountCreationHelper) {
        self.accountModelsManager = accountModelsManager
        self.creationHelper = creationHelper
    }
}

// MARK: - AccountFormViewCreator protocol conformance

extension JointAccountFormViewCreator: AccountFormViewCreator {
    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        accountModelsManager.totalCryptoAccountsCountPublisher
    }

    /// The account is created by [REDACTED_AUTHOR]
    var mainButtonTitle: String {
        Localization.commonContinue
    }

    /// The form is only the first step of the joint account creation flow, so the entered name and icon are
    /// handed over to the helper and the account itself is created once the remaining steps are done.
    func handleMainButtonTap(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountFormOperationResult {
        creationHelper.update(name: name, icon: icon)

        return .joint(creationHelper)
    }
}
