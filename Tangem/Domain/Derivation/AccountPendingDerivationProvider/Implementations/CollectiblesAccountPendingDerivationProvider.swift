//
//  CollectiblesAccountPendingDerivationProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CollectiblesAccountPendingDerivationProvider {
    let pendingDerivationsPublisher: AnyPublisher<[PendingDerivation], Never>

    init(
        coldOwnerNetwork: BlockchainNetwork,
        syncStatusProvider: CollectiblesSyncStatusProvider,
        keysProvider: KeysProvider
    ) {
        pendingDerivationsPublisher = syncStatusProvider
            .isSyncRequiredPublisher
            .map { isSyncRequired in isSyncRequired ? [coldOwnerNetwork] : [] }
            .combineLatest(keysProvider.keysPublisher)
            .map { networks, keys in
                PendingDerivationHelper.pendingDerivations(networks: networks, keys: keys)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - AccountPendingDerivationProvider protocol conformance

extension CollectiblesAccountPendingDerivationProvider: AccountPendingDerivationProvider {}
