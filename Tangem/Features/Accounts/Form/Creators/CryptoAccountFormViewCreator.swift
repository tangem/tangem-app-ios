//
//  CryptoAccountFormViewCreator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CombineExt
import Combine
import TangemLocalization
import TangemFoundation

struct CryptoAccountFormViewCreator {
    private let accountModelsManager: AccountModelsManager

    init(accountModelsManager: AccountModelsManager) {
        self.accountModelsManager = accountModelsManager
    }
}

// MARK: - AccountFormViewCreator protocol conformance

extension CryptoAccountFormViewCreator: AccountFormViewCreator {
    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        accountModelsManager.totalCryptoAccountsCountPublisher
    }

    var mainButtonTitle: String {
        Localization.accountFormTitleCreate
    }

    func handleMainButtonTap(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountFormOperationResult {
        let derivationIndex = await nextDerivationIndex()
        let operationResult = try await accountModelsManager.addCryptoAccount(name: name, icon: icon)
        let createdAccount = await createdAccountModel(withDerivationIndex: derivationIndex)

        return .crypto(operationResult: operationResult, createdAccount: createdAccount)
    }
}

// MARK: - Private

private extension CryptoAccountFormViewCreator {
    /// Accounts are created with a derivation index incremented by one from the last existing account, which makes
    /// it possible to determine the derivation index of the next newly created account from the total accounts count.
    /// Not the most robust solution, but it allows to avoid passing the id of the newly created account from the manager.
    /// - Important: Must be called before the account is added.
    func nextDerivationIndex() async -> Int? {
        try? await accountModelsManager
            .totalCryptoAccountsCountPublisher
            // The count is expected to be emitted upon subscription, the timeout is a safety net against a stalled publisher
            .timeout(.seconds(Constants.fallbackTimeout), scheduler: DispatchQueue.main)
            .async()
    }

    /// The accounts manager reports only the outcome of an operation, so the model of a just created account
    /// has to be picked up from the accounts list once it shows up there.
    /// - Parameter derivationIndex: `nil` when the index hasn't been captured before the account was added,
    ///   which leaves nothing to look the model up by.
    func createdAccountModel(withDerivationIndex derivationIndex: Int?) async -> (any CryptoAccountModel)? {
        guard let derivationIndex else {
            return nil
        }

        let accountFoundPublisher = accountModelsManager
            .cryptoAccountModelsPublisher
            .compactMap { cryptoAccountModels in
                cryptoAccountModels.first { account in
                    // The concrete type of the persistent identifier isn't known statically, hence the comparison via `AnyHashable`
                    account.id.toPersistentIdentifier().toAnyHashable() == derivationIndex.toAnyHashable()
                }
            }
            .first()
            .mapToOptional()

        let timeoutPublisher: some Publisher<(any CryptoAccountModel)?, Never> = Just(nil)
            .delay(for: .seconds(Constants.fallbackTimeout), scheduler: DispatchQueue.main)

        // One-time subscription to get the latest list of crypto accounts.
        // Falls back to `nil` from `timeoutPublisher` after a timeout if the account model isn't found.
        // The subscription outlives the task this method is called from, the same way it did before it moved here:
        // leaving the form cancels that task, and the lookup mustn't be cut short by it.
        let createdAccount: (any CryptoAccountModel)? = await withCheckedContinuation { continuation in
            var subscription: AnyCancellable?

            subscription = accountFoundPublisher
                .amb(timeoutPublisher)
                // Guards the continuation against a second value, which would be a fatal double resume
                .first()
                .receiveOnMain()
                .sink { cryptoAccountModel in
                    continuation.resume(returning: cryptoAccountModel)
                    withExtendedLifetime(subscription) {}
                }
        }

        assert(createdAccount != nil, "Newly created account with derivation index '\(derivationIndex)' was not found")

        return createdAccount
    }
}

// MARK: - Constants

private extension CryptoAccountFormViewCreator {
    enum Constants {
        static let fallbackTimeout: TimeInterval = 3.0
    }
}
