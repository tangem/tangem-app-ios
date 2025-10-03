//
//  AccountWalletManagersRepositoryAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk

@available(*, deprecated, message: "[REDACTED_TODO_COMMENT]")
final class AccountWalletManagersRepositoryAdapter {
    private let derivationIndex: Int
    private let walletManagersRepository: WalletManagersRepository

    private var isMainAccountAdapter: Bool {
        AccountModelUtils.isMainAccount(derivationIndex)
    }

    init(
        derivationIndex: Int,
        walletManagersRepository: WalletManagersRepository
    ) {
        self.derivationIndex = derivationIndex
        self.walletManagersRepository = walletManagersRepository
    }

    private func filterWalletManagers(
        _ walletManagers: [BlockchainNetwork: WalletManager]
    ) -> [BlockchainNetwork: WalletManager] {
        return walletManagers
            .filter { key, value in
                // In case of blockchains with multiple derivation paths (like Cardano), the second derivation path
                // is derived from the first one and has nothing to do with the account functionality
                // Therefore, we only use the first derivation path
                guard let derivationPath = key.derivationPaths().first else {
                    // The absence of derivation paths means that this wallet manager belongs to the main account
                    return isMainAccountAdapter
                }

                let helper = AccountDerivationPathHelper(blockchain: key.blockchain)

                guard let derivationNode = helper.extractAccountDerivationNode(from: derivationPath) else {
                    // The absence of a derivation node at the particular index in the derivation path means
                    // that this wallet manager has default derivation and belongs to the main account
                    return isMainAccountAdapter
                }

                return derivationNode.rawIndex == UInt32(derivationIndex)
            }
    }
}

// MARK: - WalletManagersRepository protocol conformance

extension AccountWalletManagersRepositoryAdapter: WalletManagersRepository {
    var walletManagersPublisher: AnyPublisher<[BlockchainNetwork: WalletManager], Never> {
        return walletManagersRepository
            .walletManagersPublisher
            .withWeakCaptureOf(self)
            .map { adapter, walletManagers in
                return adapter.filterWalletManagers(walletManagers)
            }
            .eraseToAnyPublisher()
    }
}
