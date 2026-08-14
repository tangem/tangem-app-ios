//
//  AccountFormViewCreator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// Performs the account creation for `AccountFormView`: a concrete implementation defines which kind of
/// account is created and how the model of the created account is obtained.
protocol AccountFormViewCreator {
    /// Archived + active accounts, the form shows it as the ordinal number of the account being created.
    var totalAccountsCountPublisher: AnyPublisher<Int, Never> { get }

    var mainButtonTitle: String { get }

    func handleMainButtonTap(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountFormOperationResult
}

// MARK: - Auxiliary types

enum AccountFormOperationResult {
    case crypto(operationResult: AccountOperationResult, createdAccount: (any CryptoAccountModel)?)
    case joint(JointAccountCreationHelper)
}
