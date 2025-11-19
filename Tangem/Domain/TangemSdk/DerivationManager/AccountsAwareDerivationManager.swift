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
import struct TangemSdk.DerivationPath

// [REDACTED_TODO_COMMENT]
/// One instance per account, a proxy for `AccountsAwareDerivationManager`.
final class _AccountsAwareDerivationManager {
    private let keysRepository: KeysRepository
    private let userTokensManager: UserTokensManager
    private let innerDerivationManager: DerivationManager
    private let pendingDerivationsPublisher: AnyPublisher<[PendingDerivation], Never>

    init(
        keysRepository: KeysRepository,
        userTokensManager: UserTokensManager,
        innerDerivationManager: DerivationManager,
    ) {
        self.keysRepository = keysRepository
        self.userTokensManager = userTokensManager
        self.innerDerivationManager = innerDerivationManager

        pendingDerivationsPublisher = userTokensManager
            .userTokensPublisher
            .combineLatest(keysRepository.keysPublisher)
            .map { entries, keys in
                return entries.compactMap { entry in
                    PendingDerivation.Helper.pendingDerivation(network: entry.blockchainNetwork, keys: keys)
                }
            }
            .eraseToAnyPublisher()
    }
}

extension _AccountsAwareDerivationManager: DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        pendingDerivationsPublisher
            .map { !$0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var pendingDerivationsCount: AnyPublisher<Int, Never> {
        pendingDerivationsPublisher
            .map { pending in
                pending.reduce(0) { $0 + $1.paths.count }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func shouldDeriveKeys(networksToRemove: [BlockchainNetwork], networksToAdd: [BlockchainNetwork]) -> Bool {
        innerDerivationManager.shouldDeriveKeys(networksToRemove: networksToRemove, networksToAdd: networksToAdd)
    }

    func deriveKeys(completion: @escaping (Result<Void, any Error>) -> Void) {
        innerDerivationManager.deriveKeys(completion: completion)
    }
}

// [REDACTED_TODO_COMMENT]
protocol _DerivationManager {
    func configure(with keysDerivingProvider: KeysDerivingProvider)
    func configure(with accountModelsManager: AccountModelsManager)
}

// [REDACTED_TODO_COMMENT]
/// One instance per user wallet.
final class AccountsAwareDerivationManager {
    private let keysRepository: KeysRepository
    private var accountModelsManagerSubscription: AnyCancellable?
    private weak var keysDerivingProvider: KeysDerivingProvider?
    private var pendingDerivations: [PendingDerivation] = []
    private var bag: Set<AnyCancellable> = []

    private lazy var debouncer = Debouncer(interval: Constants.deriveKeysDebounceInterval) { [weak self] in
        self?.deriveKeysInternal(completion: $0)
    }

    init(keysRepository: KeysRepository) {
        self.keysRepository = keysRepository
    }

    private func process(entries: [TokenItem], keys: [KeyInfo]) {
        pendingDerivations = entries.compactMap { entry in
            PendingDerivation.Helper.pendingDerivation(network: entry.blockchainNetwork, keys: keys)
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

        let pendingDerivationsKeyed = PendingDerivation.Helper.pendingDerivationsKeyedByPublicKeys(pendingDerivations)

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

// MARK: - _DerivationManager protocol conformance

extension AccountsAwareDerivationManager: _DerivationManager {
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

// MARK: - DerivationManager protocol conformance

extension AccountsAwareDerivationManager: DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        // [REDACTED_TODO_COMMENT]
        preconditionFailure("Use `_AccountsAwareDerivationManager.hasPendingDerivations` instead")
    }

    var pendingDerivationsCount: AnyPublisher<Int, Never> {
        // [REDACTED_TODO_COMMENT]
        preconditionFailure("Use `_AccountsAwareDerivationManager.pendingDerivationsCount` instead")
    }

    /// - Note: The implementation is equivalent to `CommonDerivationManager.shouldDeriveKeys(networksToRemove:networksToAdd:)`,
    func shouldDeriveKeys(networksToRemove: [BlockchainNetwork], networksToAdd: [BlockchainNetwork]) -> Bool {
        guard
            let interactor = keysDerivingProvider?.keysDerivingInteractor,
            interactor.requiresCard
        else {
            return false
        }

        let keys = keysRepository.keys
        let addingDerivations = networksToAdd.compactMap { PendingDerivation.Helper.pendingDerivation(network: $0, keys: keys) }

        // Filter pending derivations by removing those that belong to networks scheduled for removal.
        // This ensures we only consider derivations that will still be relevant after the update.
        let filteredPendingDerivations = pendingDerivations.filter { !networksToRemove.contains($0.network) }

        // Derivation is needed if the user adds networks requiring a card,
        // or if unresolved derivations remain for existing networks.
        return addingDerivations.isNotEmpty || filteredPendingDerivations.isNotEmpty
    }

    /// - Note: Multiple `_AccountsAwareDerivationManager` may call this method simultaneously, so we need to debounce such calls.
    func deriveKeys(completion: @escaping (Result<Void, any Error>) -> Void) {
        ensureOnMainQueue() // `debouncer` is lazy, so we need to make sure it's created on serial queue
        debouncer.debounce(withCompletion: completion)
    }
}

// MARK: - Constants

private extension AccountsAwareDerivationManager {
    enum Constants {
        /// Delay to get more time to update Ui and hide generate addresses sheet under the hood
        /// Taken as is from CommonDerivationManager, looks like a workaround for some UI issues
        static let deriveKeysCompletionDelay = 0.2
        static let deriveKeysDebounceInterval = 0.3
    }
}

// MARK: - Auxiliary types

// [REDACTED_TODO_COMMENT]
struct PendingDerivation {
    let network: BlockchainNetwork
    let masterKey: KeyInfo
    let paths: [DerivationPath]
}

extension PendingDerivation {
    // [REDACTED_TODO_COMMENT]
    enum Helper {
        static func pendingDerivation(network: BlockchainNetwork, keys: [KeyInfo]) -> PendingDerivation? {
            let curve = network.blockchain.curve

            let derivationPaths = network.derivationPaths()
            guard let masterKey = keys.first(where: { $0.curve == curve }) else {
                return nil
            }

            let pendingDerivationPaths = derivationPaths.filter { derivationPath in
                !masterKey.derivedKeys.keys.contains { $0 == derivationPath }
            }
            guard pendingDerivationPaths.isNotEmpty else {
                return nil
            }

            return PendingDerivation(
                network: network,
                masterKey: masterKey,
                paths: pendingDerivationPaths
            )
        }

        static func pendingDerivationsKeyedByPublicKeys(_ derivations: [PendingDerivation]) -> [Data: [DerivationPath]] {
            return derivations.reduce(into: [:]) { dict, derivation in
                dict[derivation.masterKey.publicKey, default: []] += derivation.paths
            }
        }
    }
}
