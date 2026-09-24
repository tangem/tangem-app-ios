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
    /// The joint account flow titles its steps itself, so the form adds no title of its own.
    var navigationTitle: String { "" }
    var mainButtonTitle: String { Localization.commonContinue }

    /// Unlike a crypto account, a joint one opens with its name already filled in, so that the user can go on
    /// without naming it.
    var initialAccountName: String { Localization.commonJointAccount }

    /// Derivation is a matter of the wallet's own accounts; a joint account is not one of them and says nothing
    /// about it.
    var showsAccountIndexDescription: Bool { false }

    /// - Note: The joint accounts are counted apart from the wallet's own ones, and it is their count the form shows
    /// as the ordinal number of the account being created.
    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        accountModelsManager.totalJointAccountsCountPublisher
    }

    /// The form is only the first step of the joint account creation flow, so the entered name and icon are
    /// handed over to the helper and the account itself is created once the remaining steps are done.
    func handleMainButtonTap(name: String, icon: AccountModel.CompositeIcon) async throws -> AccountFormOperationResult {
        creationHelper.update(name: name, icon: icon)

        return .joint(creationHelper)
    }
}
