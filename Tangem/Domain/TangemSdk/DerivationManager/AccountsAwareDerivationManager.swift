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
    private let pendingDerivationsPublisher: AnyPublisher<[PendingDerivation], Never>

    init(keysRepository: KeysRepository, userTokensManager: UserTokensManager) {
        self.keysRepository = keysRepository
        self.userTokensManager = userTokensManager

        pendingDerivationsPublisher = userTokensManager
            .userTokensPublisher
            .combineLatest(keysRepository.keysPublisher)
            .map { entries, keys in
                return entries.compactMap { entry in
                    PendingDerivation.Extractor.pendingDerivation(network: entry.blockchainNetwork, keys: keys)
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
        fatalError()
    }

    func deriveKeys(completion: @escaping (Result<Void, any Error>) -> Void) {
        fatalError()
    }
}

// [REDACTED_TODO_COMMENT]
/// One instance per user wallet.
final class AccountsAwareDerivationManager {
    private let keysRepository: KeysRepository
    private let accountModelsManager: AccountModelsManager
    private weak var keysDerivingProvider: KeysDerivingProvider?
    private let pendingDerivations: CurrentValueSubject<[PendingDerivation], Never> = .init([])
    private var bag: Set<AnyCancellable> = []

    init(
        keysRepository: KeysRepository,
        accountModelsManager: AccountModelsManager
    ) {
        self.keysRepository = keysRepository
        self.accountModelsManager = accountModelsManager
        bind()
    }

    func configure(with keysDerivingProvider: KeysDerivingProvider) {
        assert(self.keysDerivingProvider == nil, "An attempt to override already configured keysDerivingProvider instance")
        self.keysDerivingProvider = keysDerivingProvider
    }

    private func bind() {
        accountModelsManager
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
            .store(in: &bag)
    }

    private func process(entries: [TokenItem], keys: [KeyInfo]) {
        let derivations = entries.compactMap { entry in
            pendingDerivation(network: entry.blockchainNetwork, keys: keys)
        }
        pendingDerivations.send(derivations)
    }

    private func pendingDerivation(network: BlockchainNetwork, keys: [KeyInfo]) -> PendingDerivation? {
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
}

// MARK: - Auxiliary types

// [REDACTED_TODO_COMMENT]
struct PendingDerivation {
    let network: BlockchainNetwork
    let masterKey: KeyInfo
    let paths: [DerivationPath]
}

extension PendingDerivation {
    enum Extractor {
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
    }
}
