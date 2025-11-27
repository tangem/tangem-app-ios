//
//  DerivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk
import Combine
import BlockchainSdk

// [REDACTED_TODO_COMMENT]
final class CommonDerivationManager {
    private let keysRepository: KeysRepository
    private let userTokensManager: UserTokensManager
    private weak var keysDerivingProvider: KeysDerivingProvider?
    private var bag = Set<AnyCancellable>()
    private let pendingDerivations: CurrentValueSubject<[PendingDerivation], Never> = .init([])

    init(keysRepository: KeysRepository, userTokensManager: UserTokensManager) {
        self.keysRepository = keysRepository
        self.userTokensManager = userTokensManager
        bind()
    }

    private func bind() {
        userTokensManager.userTokensPublisher
            .combineLatest(keysRepository.keysPublisher)
            .sink { [weak self] entries, keys in
                self?.process(entries, keys)
            }
            .store(in: &bag)
    }

    private func process(_ entries: [TokenItem], _ keys: [KeyInfo]) {
        let derivations = entries.compactMap { entry in
            PendingDerivationHelper.pendingDerivation(network: entry.blockchainNetwork, keys: keys)
        }
        pendingDerivations.send(derivations)
    }
}

// MARK: - DerivationManager protocol conformance

extension CommonDerivationManager: DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        pendingDerivations
            .map { !$0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var pendingDerivationsCount: AnyPublisher<Int, Never> {
        pendingDerivations
            .map { pending in
                pending.reduce(0) { $0 + $1.paths.count }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func shouldDeriveKeys(networksToRemove: [BlockchainNetwork], networksToAdd: [BlockchainNetwork]) -> Bool {
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
        let filteredPendingDerivations = pendingDerivations.value.filter { !networksToRemove.contains($0.network) }

        // Derivation is needed if the user adds networks requiring a card,
        // or if unresolved derivations remain for existing networks.
        return addingDerivations.isNotEmpty || filteredPendingDerivations.isNotEmpty
    }

    func deriveKeys(completion: @escaping (Result<Void, Error>) -> Void) {
        guard
            pendingDerivations.value.isNotEmpty,
            let interactor = keysDerivingProvider?.keysDerivingInteractor
        else {
            completion(.success(()))
            return
        }

        let pendingDerivationsKeyed = PendingDerivationHelper.pendingDerivationsKeyedByPublicKeys(pendingDerivations.value)

        interactor.deriveKeys(derivations: pendingDerivationsKeyed) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let response):
                keysRepository.update(derivations: response)

                // delay to get more time to update ui and hide generate addresses sheet under the hood
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    completion(.success(()))
                }
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(interactor) {}
        }
    }
}

// MARK: - DerivationDependenciesConfigurable protocol conformance

extension CommonDerivationManager: DerivationDependenciesConfigurable {
    func configure(with keysDerivingProvider: KeysDerivingProvider) {
        assert(self.keysDerivingProvider == nil, "An attempt to override already configured keysDerivingProvider instance")
        self.keysDerivingProvider = keysDerivingProvider
    }

    func configure(with accountModelsManager: AccountModelsManager) {
        // No-op, no accounts supported
    }
}
