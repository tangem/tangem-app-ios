//
//  AccountDerivationManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// One instance per unique account, a proxy for `AccountsAwareDerivationManager`.
final class AccountDerivationManager {
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
                entries.flatMap { PendingDerivationHelper.pendingDerivations(network: $0.blockchainNetwork, keys: keys) }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - DerivationManager protocol conformance

extension AccountDerivationManager: DerivationManager {
    var hasPendingDerivations: AnyPublisher<Bool, Never> {
        pendingDerivationsPublisher
            .map { !$0.isEmpty }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var pendingDerivationsCount: AnyPublisher<Int, Never> {
        pendingDerivationsPublisher
            .map { pending in
                // In some rare edge cases (old wallets, etc) there might be multiple master keys with the same curve.
                // All such master keys have the same set of pending derivations, so we need to select only master keys
                // distinct by `network` to avoid counting the same pending derivations but for different master keys multiple times.
                pending
                    .unique(by: \.network)
                    .reduce(0) { $0 + $1.paths.count }
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
