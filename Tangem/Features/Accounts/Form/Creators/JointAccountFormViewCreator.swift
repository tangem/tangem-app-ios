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
    private let creationHelper: JointAccountCreationHelper
    private let walletSelection: AccountFormWalletSelection

    init(creationHelper: JointAccountCreationHelper, walletSelection: AccountFormWalletSelection) {
        self.creationHelper = creationHelper
        self.walletSelection = walletSelection
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
    /// as the ordinal number of the account being created. Follows the wallet selection, since the ordinal number
    /// belongs to the wallet the account is created in.
    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        creationHelper
            .userWalletModelPublisher
            .map { $0.accountModelsManager.totalJointAccountsCountPublisher }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    var walletPublisher: AnyPublisher<AccountFormWallet?, Never> {
        creationHelper
            .userWalletModelPublisher
            .map { [walletSelection] in walletSelection.wallet(for: $0) }
            .eraseToAnyPublisher()
    }

    var selectableWallets: [any UserWalletModel] {
        UserWalletModelsProvider.accountCreationCandidates(for: .joint)
    }

    /// The form is only the first step of the joint account creation flow, so the entered name and icon are
    /// handed over to the helper and the account itself is created once the remaining steps are done.
    func handleMainButtonTap(name: String, icon: AccountModel.CompositeIcon) async throws -> AccountFormOperationResult {
        creationHelper.update(name: name, icon: icon)

        return .joint(creationHelper)
    }

    func selectWallet(_ userWalletModel: any UserWalletModel) {
        creationHelper.update(userWalletModel: userWalletModel)
    }
}
