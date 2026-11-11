//
//  CryptoAccountPendingDerivationProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CryptoAccountPendingDerivationProvider {
    let pendingDerivationsPublisher: AnyPublisher<[PendingDerivation], Never>

    init(userTokensManager: UserTokensManager, keysRepository: KeysRepository, isDerivationSupported: Bool) {
        guard isDerivationSupported else {
            pendingDerivationsPublisher = .just(output: [])
            return
        }

        pendingDerivationsPublisher = userTokensManager
            .userTokensPublisher
            .map { $0.map(\.blockchainNetwork) }
            .combineLatest(keysRepository.keysPublisher)
            .map { networks, keys in
                PendingDerivationHelper.pendingDerivations(networks: networks, keys: keys)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - AccountPendingDerivationProvider protocol conformance

extension CryptoAccountPendingDerivationProvider: AccountPendingDerivationProvider {}
