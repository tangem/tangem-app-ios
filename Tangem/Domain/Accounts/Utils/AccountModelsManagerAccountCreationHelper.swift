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

    /// - Parameter identity: What the account was created under, as the creation call answered.
    func createdCryptoAccountModel(with identity: CryptoAccountDerivationIdentity) async -> (any CryptoAccountModel)? {
        let cryptoAccountModelsPublisher = AccountModelsAggregator(.crypto, .joint).modelsPublisher(from: accountModelsManager)

        return await createdAccountModel(for: identity, in: cryptoAccountModelsPublisher) {
            $0.id.toPersistentIdentifier().toAnyHashable()
        }
    }

    /// - Parameter identity: What the account was created under, as the creation call answered.
    func createdJointAccountModel(with identity: CryptoAccountDerivationIdentity) async -> (any JointAccountModel)? {
        let jointAccountModelsPublisher = accountModelsManager.accountModelsPublisher.map { accountModels in
            accountModels.flatMap { accountModel -> [any JointAccountModel] in
                switch accountModel {
                case .joint(let jointAccountModels): jointAccountModels
                case .standard, .tangemPay, .polymarket, .collectibles: []
                }
            }
        }
        .eraseToAnyPublisher()

        return await createdAccountModel(for: identity, in: jointAccountModelsPublisher) {
            $0.id.toPersistentIdentifier().toAnyHashable()
        }
    }
}

// MARK: - Private

private extension AccountModelsManagerAccountCreationHelper {
    /// The accounts manager reports only the outcome of an operation, so the model of a just created account
    /// has to be picked up from the accounts list once it shows up there.
    /// - Parameter identifiedBy: How a model of this kind names itself, which cannot be read off an existential
    /// on its own.
    func createdAccountModel<Model>(
        for derivationIdentity: CryptoAccountDerivationIdentity,
        in accountModels: AnyPublisher<[Model], Never>,
        identifiedBy identifierOf: @escaping (Model) -> AnyHashable
    ) async -> Model? {
        // The concrete type of the persistent identifier isn't known statically, hence the comparison via `AnyHashable`
        let identifier = derivationIdentity.toPersistentIdentifier().toAnyHashable()

        let accountFoundPublisher = accountModels
            .compactMap { accountModels in
                accountModels.first { identifierOf($0) == identifier }
            }
            .first()
            .mapToOptional()
            // `amb` takes a bare completion for a win and cancels the loser, so a source that finishes without
            // ever matching has to resolve to `nil` the way the timeout does — otherwise the continuation below
            // would never be resumed.
            .replaceEmpty(with: nil)

        let timeoutPublisher: some Publisher<Model?, Never> = Just(nil)
            .delay(for: .seconds(Constants.fallbackTimeout), scheduler: DispatchQueue.main)

        // One-time subscription to get the latest list of accounts.
        // Falls back to `nil` from `timeoutPublisher` after a timeout if the account model isn't found.
        // The subscription outlives the task this method is called from: leaving the form cancels that task,
        // and the lookup mustn't be cut short by it.
        let createdAccount: Model? = await withCheckedContinuation { continuation in
            var subscription: AnyCancellable?

            subscription = accountFoundPublisher
                .amb(timeoutPublisher)
                // Guards the continuation against a second value, which would be a fatal double resume
                .first()
                .receiveOnMain()
                .sink { accountModel in
                    continuation.resume(returning: accountModel)
                    withExtendedLifetime(subscription) {}
                }
        }

        assert(createdAccount != nil, "Newly created account '\(derivationIdentity)' was not found")

        return createdAccount
    }
}

// MARK: - Constants

private extension AccountModelsManagerAccountCreationHelper {
    enum Constants {
        static let fallbackTimeout: TimeInterval = 3.0
    }
}
