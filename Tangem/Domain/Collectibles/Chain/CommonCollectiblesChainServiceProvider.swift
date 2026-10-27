//
//  CommonCollectiblesChainServiceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemCollectibles
import TangemFoundation

final class CommonCollectiblesChainServiceProvider {
    private let factoryProvider: WalletNetworkServiceFactoryProvider

    /// `uncheckedState` since `SolanaSponsoredTransactionService` is not `Sendable`.
    private let serviceSlot = OSAllocatedUnfairLock<SolanaSponsoredTransactionService?>(uncheckedState: nil)

    init(factoryProvider: WalletNetworkServiceFactoryProvider = WalletNetworkServiceFactoryProvider()) {
        self.factoryProvider = factoryProvider
    }
}

// MARK: - CollectiblesChainServiceProvider protocol conformance

extension CommonCollectiblesChainServiceProvider: CollectiblesChainServiceProvider {
    /// Built on first use: endpoint resolution can throw, and that failure must read as a failed call,
    /// not tear down the dependency graph. Only a successful build is kept, so a failure is retried.
    func service() throws -> any CollectiblesChainService {
        try serviceSlot.withLock { slot in
            if let slot {
                return slot
            }

            let service = try SolanaSponsoredTransactionService(
                blockchain: CollectiblesChainEnvironment.blockchain,
                walletNetworkServiceFactory: factoryProvider.factory
            )
            slot = service

            return service
        }
    }
}
