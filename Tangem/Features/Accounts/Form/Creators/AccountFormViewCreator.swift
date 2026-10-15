//
//  AccountFormViewCreator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import enum TangemUI.ThumbnailWalletViewType

/// Performs the account creation for `AccountFormView`: a concrete implementation defines which kind of
/// account is created and how the model of the created account is obtained.
protocol AccountFormViewCreator {
    var navigationTitle: String { get }
    var mainButtonTitle: String { get }

    /// The name the form opens with; empty means the user starts from a blank field.
    var initialAccountName: String { get }

    /// Whether the form explains under the name field which ordinal number the account takes, and so which
    /// derivation it gets.
    var showsAccountIndexDescription: Bool { get }

    /// Archived + active accounts, the form shows it as the ordinal number of the account being created.
    var totalAccountsCountPublisher: AnyPublisher<Int, Never> { get }

    /// The wallet the account is created in, shown by the form as a row that opens the wallet selection when the
    /// wallet can be changed.
    /// - Note: `nil` hides the row.
    var walletPublisher: AnyPublisher<AccountFormWallet?, Never> { get }

    var selectableWallets: [any UserWalletModel] { get }

    func handleMainButtonTap(name: String, icon: AccountModel.CompositeIcon) async throws -> AccountFormOperationResult

    func selectWallet(_ userWalletModel: any UserWalletModel)
}

extension AccountFormViewCreator {
    var initialAccountName: String { "" }
    var showsAccountIndexDescription: Bool { true }
}

// MARK: - Auxiliary types

enum AccountFormOperationResult {
    case crypto(operationResult: AccountOperationResult, createdAccount: (any CryptoAccountModel)?)
    case joint(JointAccountCreationHelper)
}

struct AccountFormWallet {
    let id: UserWalletId
    let name: String
    let thumbnailType: ThumbnailWalletViewType?
    let isSelectable: Bool
}

enum AccountFormWalletSelection {
    case hidden
    case fixed
    case selectable

    func wallet(for userWalletModel: any UserWalletModel) -> AccountFormWallet? {
        let isSelectable: Bool

        switch self {
        case .hidden:
            return nil
        case .fixed:
            isSelectable = false
        case .selectable:
            isSelectable = true
        }

        return AccountFormWallet(
            id: userWalletModel.userWalletId,
            name: userWalletModel.name,
            thumbnailType: userWalletModel.config.walletThumbnailType,
            isSelectable: isSelectable
        )
    }
}
