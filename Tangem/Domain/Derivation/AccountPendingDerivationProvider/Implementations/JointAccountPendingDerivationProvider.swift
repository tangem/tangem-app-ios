//
//  JointAccountPendingDerivationProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class JointAccountPendingDerivationProvider {
    let pendingDerivationsPublisher: AnyPublisher<[PendingDerivation], Never>

    init(derivationIndex: Int, userTokensManager: UserTokensManager, keysRepository: KeysRepository, isDerivationSupported: Bool) {
        guard isDerivationSupported else {
            pendingDerivationsPublisher = .just(output: [])
            return
        }

        let accountNetwork: BlockchainNetwork

        do {
            accountNetwork = try JointAccountKeyPath.blockchainNetwork(forAccountAtIndex: derivationIndex)
        } catch {
            PendingDerivationsLogger.error("The joint account index \(derivationIndex) has no derivation path", error: error)
            pendingDerivationsPublisher = .just(output: [])
            return
        }

        pendingDerivationsPublisher = userTokensManager
            .userTokensPublisher
            .map { userTokens in userTokens.isEmpty ? [accountNetwork] : userTokens.map(\.blockchainNetwork) }
            .combineLatest(keysRepository.keysPublisher)
            .map { networks, keys in
                PendingDerivationHelper.pendingDerivations(networks: networks, keys: keys)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - AccountPendingDerivationProvider protocol conformance

extension JointAccountPendingDerivationProvider: AccountPendingDerivationProvider {}
