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
    private let userWalletModelSubject: CurrentValueSubject<any UserWalletModel, Never>
    private let walletSelection: AccountFormWalletSelection

    init(
        userWalletModelSubject: CurrentValueSubject<any UserWalletModel, Never>,
        walletSelection: AccountFormWalletSelection
    ) {
        self.userWalletModelSubject = userWalletModelSubject
        self.walletSelection = walletSelection
    }
}

// MARK: - AccountFormViewCreator protocol conformance

extension CryptoAccountFormViewCreator: AccountFormViewCreator {
    var navigationTitle: String { Localization.accountFormTitleCreate }

    var mainButtonTitle: String { Localization.commonCreateAccount }

    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        userWalletModelSubject
            .map { $0.accountModelsManager.totalCryptoAccountsCountPublisher }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    var walletPublisher: AnyPublisher<AccountFormWallet?, Never> {
        userWalletModelSubject
            .map { [walletSelection] in walletSelection.wallet(for: $0) }
            .eraseToAnyPublisher()
    }

    var selectableWallets: [any UserWalletModel] {
        UserWalletModelsProvider.accountCreationCandidates(for: .crypto)
    }

    func handleMainButtonTap(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountFormOperationResult {
        let accountModelsManager = userWalletModelSubject.value.accountModelsManager
        let creationResult = try await accountModelsManager.addCryptoAccount(name: name, icon: icon)
        let createdAccount = await AccountModelsManagerAccountCreationHelper(accountModelsManager: accountModelsManager)
            .createdCryptoAccountModel(with: creationResult.derivationIdentity)

        return .crypto(operationResult: creationResult.operationResult, createdAccount: createdAccount)
    }

    func selectWallet(_ userWalletModel: any UserWalletModel) {
        userWalletModelSubject.send(userWalletModel)
    }
}
