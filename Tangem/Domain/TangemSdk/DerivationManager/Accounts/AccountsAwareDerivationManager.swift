//
//  AccountsAwareDerivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

/// One instance per unique user wallet.
final class AccountsAwareDerivationManager {
    private let keysRepository: KeysRepository
    private var accountModelsManagerSubscription: AnyCancellable?
    private weak var keysDerivingProvider: KeysDerivingProvider?
    private var pendingDerivations: [PendingDerivation] = []

    private lazy var debouncer = Debouncer(interval: Constants.deriveKeysDebounceInterval) { [weak self] in
        self?.deriveKeysInternal(completion: $0)
    }

    init(keysRepository: KeysRepository) {
        self.keysRepository = keysRepository
    }

    private func process(entries: [TokenItem], keys: [KeyInfo]) {
        pendingDerivations = entries.compactMap { entry in
            PendingDerivationHelper.pendingDerivation(network: entry.blockchainNetwork, keys: keys)
        }
    }

    /// - Note: The implementation is equivalent to `CommonDerivationManager.deriveKeys(completion:)`,
    private func deriveKeysInternal(completion: @escaping (Result<Void, any Error>) -> Void) {
        guard
            pendingDerivations.isNotEmpty,
            let interactor = keysDerivingProvider?.keysDerivingInteractor
        else {
            completion(.success(()))
            return
        }

        let pendingDerivationsKeyed = PendingDerivationHelper.pendingDerivationsKeyedByPublicKeys(pendingDerivations)

        interactor.deriveKeys(derivations: pendingDerivationsKeyed) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let response):
                keysRepository.update(derivations: response)

                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.deriveKeysCompletionDelay) {
                    completion(.success(()))
                }
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(interactor) {}
        }
    }
}

// MARK: - DerivationManager protocol conformance

extension AccountsAwareDerivationManager: DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        // [REDACTED_TODO_COMMENT]
        preconditionFailure("Use `AccountDerivationManager.hasPendingDerivations` instead")
    }

    var pendingDerivationsCount: AnyPublisher<Int, Never> {
        // [REDACTED_TODO_COMMENT]
        preconditionFailure("Use `AccountDerivationManager.pendingDerivationsCount` instead")
    }

    /// - Note: The implementation is equivalent to `CommonDerivationManager.shouldDeriveKeys(networksToRemove:networksToAdd:)`,
    func shouldDeriveKeys(networksToRemove: [BlockchainNetwork], networksToAdd: [BlockchainNetwork]) -> Bool {
        assert(
            keysDerivingProvider != nil && accountModelsManagerSubscription != nil,
            "AccountsAwareDerivationManager is not configured with required dependencies"
        )

        guard
            let interactor = keysDerivingProvider?.keysDerivingInteractor,
            interactor.requiresCard
        else {
            return false
        }

        let keys = keysRepository.keys
        let addingDerivations = networksToAdd.compactMap { PendingDerivationHelper.pendingDerivation(network: $0, keys: keys) }

        // Filter pending derivations by removing those that belong to networks scheduled for removal.
        // This ensures we only consider derivations that will still be relevant after the update.
        let filteredPendingDerivations = pendingDerivations.filter { !networksToRemove.contains($0.network) }

        // Derivation is needed if the user adds networks requiring a card,
        // or if unresolved derivations remain for existing networks.
        return addingDerivations.isNotEmpty || filteredPendingDerivations.isNotEmpty
    }

    func deriveKeys(completion: @escaping (Result<Void, any Error>) -> Void) {
        assert(
            keysDerivingProvider != nil && accountModelsManagerSubscription != nil,
            "AccountsAwareDerivationManager is not configured with required dependencies"
        )

        // `debouncer` is lazy (and lazy vars are not thread-safe), so we need to make sure it's created on serial queue
        ensureOnMainQueue()
        // Multiple `AccountDerivationManager` instances may call this method simultaneously, so we need to debounce such calls.
        debouncer.debounce(withCompletion: completion)
    }
}

// MARK: - DerivationDependenciesConfigurable protocol conformance

extension AccountsAwareDerivationManager: DerivationDependenciesConfigurable {
    func configure(with keysDerivingProvider: KeysDerivingProvider) {
        assert(self.keysDerivingProvider == nil, "An attempt to override already configured keysDerivingProvider instance")
        self.keysDerivingProvider = keysDerivingProvider
    }

    func configure(with accountModelsManager: AccountModelsManager) {
        assert(accountModelsManagerSubscription == nil, "An attempt to override already configured accountModelsManager subscription")

        accountModelsManagerSubscription = accountModelsManager
            .cryptoAccountModelsPublisher
            .flatMapLatest { cryptoAccountModels -> AnyPublisher<[TokenItem], Never> in
                guard cryptoAccountModels.isNotEmpty else {
                    return .just(output: [])
                }

                return cryptoAccountModels
                    .map { cryptoAccountModel in
                        cryptoAccountModel
                            .userTokensManager
                            .userTokensPublisher
                    }
                    .combineLatest()
                    .map { $0.flattened() }
                    .eraseToAnyPublisher()
            }
            .combineLatest(keysRepository.keysPublisher)
            .withWeakCaptureOf(self)
            .sink { manager, input in
                let (entries, keys) = input
                manager.process(entries: entries, keys: keys)
            }
    }
}

// MARK: - Constants

private extension AccountsAwareDerivationManager {
    enum Constants {
        /// Delay to get more time to update UI and hide generate addresses sheet under the hood
        /// Taken as is from CommonDerivationManager, looks like a workaround for some UI issues
        static let deriveKeysCompletionDelay = 0.2
        static let deriveKeysDebounceInterval = 0.3
    }
}
