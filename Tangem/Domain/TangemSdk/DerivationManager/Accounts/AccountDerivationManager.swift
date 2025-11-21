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
                return entries.compactMap { entry in
                    PendingDerivationHelper.pendingDerivation(network: entry.blockchainNetwork, keys: keys)
                }
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
