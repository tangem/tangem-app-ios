//
//  CryptoAccountFormViewCreator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization

struct CryptoAccountFormViewCreator {
    private let accountModelsManager: AccountModelsManager

    init(accountModelsManager: AccountModelsManager) {
        self.accountModelsManager = accountModelsManager
    }
}

// MARK: - AccountFormViewCreator protocol conformance

extension CryptoAccountFormViewCreator: AccountFormViewCreator {
    var navigationTitle: String { Localization.accountFormTitleCreate }

    var mainButtonTitle: String { Localization.accountFormTitleCreate }

    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        accountModelsManager.totalCryptoAccountsCountPublisher
    }

    func handleMainButtonTap(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountFormOperationResult {
        let creationResult = try await accountModelsManager.addCryptoAccount(name: name, icon: icon)
        let createdAccount = await AccountModelsManagerAccountCreationHelper(accountModelsManager: accountModelsManager)
            .createdCryptoAccountModel(with: creationResult.derivationIdentity)

        return .crypto(operationResult: creationResult.operationResult, createdAccount: createdAccount)
    }
}
