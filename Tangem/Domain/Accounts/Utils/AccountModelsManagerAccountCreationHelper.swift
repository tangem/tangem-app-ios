//
//  AccountModelsManagerAccountCreationHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

struct AccountModelsManagerAccountCreationHelper {
    let accountModelsManager: AccountModelsManager

    /// The accounts manager reports only the outcome of an operation, so the model of a just created account
    /// has to be picked up from the accounts list once it shows up there.
    /// - Parameter identity: What the account was created under, as the endpoint answered when it was created.
    func createdCryptoAccountModel(with identity: CryptoAccountDerivationIdentity) async -> (any CryptoAccountModel)? {
        // The concrete type of the persistent identifier isn't known statically, hence the comparison via `AnyHashable`
        let identifier = identity.toPersistentIdentifier().toAnyHashable()

        let accountFoundPublisher = AccountCryptoModelsAggregator
            .cryptoAccountModelsPublisher(from: accountModelsManager)
            .compactMap { cryptoAccountModels in
                cryptoAccountModels.first { account in
                    account.id.toPersistentIdentifier().toAnyHashable() == identifier
                }
            }
            .first()
            .mapToOptional()
            // `amb` takes a bare completion for a win and cancels the loser, so a source that finishes without
            // ever matching has to resolve to `nil` the way the timeout does — otherwise the continuation below
            // would never be resumed.
            .replaceEmpty(with: nil)

        let timeoutPublisher: some Publisher<(any CryptoAccountModel)?, Never> = Just(nil)
            .delay(for: .seconds(Constants.fallbackTimeout), scheduler: DispatchQueue.main)

        // One-time subscription to get the latest list of crypto accounts.
        // Falls back to `nil` from `timeoutPublisher` after a timeout if the account model isn't found.
        // The subscription outlives the task this method is called from: leaving the form cancels that task,
        // and the lookup mustn't be cut short by it.
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

        assert(createdAccount != nil, "Newly created account '\(identity)' was not found")

        return createdAccount
    }
}

// MARK: - Constants

private extension AccountModelsManagerAccountCreationHelper {
    enum Constants {
        static let fallbackTimeout: TimeInterval = 3.0
    }
}
