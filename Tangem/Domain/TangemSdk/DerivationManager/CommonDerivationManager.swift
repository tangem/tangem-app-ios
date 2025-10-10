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

class CommonDerivationManager {
    private let keysRepository: KeysRepository
    private let userTokenListManager: UserTokenListManager

    private var bag = Set<AnyCancellable>()
    private let pendingDerivations: CurrentValueSubject<[PendingDerivation], Never> = .init([])

    init(keysRepository: KeysRepository, userTokenListManager: UserTokenListManager) {
        self.keysRepository = keysRepository
        self.userTokenListManager = userTokenListManager
        bind()
    }

    private func bind() {
        userTokenListManager.userTokensPublisher
            .combineLatest(keysRepository.keysPublisher)
            .sink { [weak self] entries, keys in
                self?.process(entries, keys)
            }
            .store(in: &bag)
    }

    private func process(_ entries: [StorageEntry], _ keys: [KeyInfo]) {
        let derivations = entries.compactMap { entry in
            pendingDerivation(network: entry.blockchainNetwork, keys: keys)
        }
        pendingDerivations.send(derivations)
    }
}

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

    func shouldDeriveKeys(networksToRemove: [BlockchainNetwork], networksToAdd: [BlockchainNetwork], interactor: KeysDeriving) -> Bool {
        guard interactor.requiresCard else {
            return false
        }

        let keys = keysRepository.keys
        let addingDerivations = networksToAdd.compactMap { pendingDerivation(network: $0, keys: keys) }

        // Filter pending derivations by removing those that belong to networks scheduled for removal.
        // This ensures we only consider derivations that will still be relevant after the update.
        let filteredPendingDerivations = pendingDerivations.value.filter { !networksToRemove.contains($0.network) }

        // Derivation is needed if the user adds networks requiring a card,
        // or if unresolved derivations remain for existing networks.
        return addingDerivations.isNotEmpty || filteredPendingDerivations.isNotEmpty
    }

    func deriveKeys(interactor: KeysDeriving, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !pendingDerivations.value.isEmpty else {
            completion(.success(()))
            return
        }

        interactor.deriveKeys(derivations: pendingDerivationsData()) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let response):
                keysRepository.update(derivations: response)

                // delay to get more time to update ui and hide generate addresses sheet under thе hood
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

// MARK: - Private methods

private extension CommonDerivationManager {
    func pendingDerivation(network: BlockchainNetwork, keys: [KeyInfo]) -> PendingDerivation? {
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

    func pendingDerivationsData() -> [Data: [DerivationPath]] {
        pendingDerivations.value.reduce(into: [:]) { dict, derivation in
            dict[derivation.masterKey.publicKey, default: []] += derivation.paths
        }
    }
}

// MARK: - Types

private extension CommonDerivationManager {
    struct PendingDerivation {
        let network: BlockchainNetwork
        let masterKey: KeyInfo
        let paths: [DerivationPath]
    }
}
