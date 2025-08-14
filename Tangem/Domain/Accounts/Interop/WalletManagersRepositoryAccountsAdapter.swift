//
//  WalletManagersRepositoryAccountsAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk

@available(*, deprecated, message: "Test only for interop/development purposes, doesn't work correctly with main account, will be removed in the future")
final class WalletManagersRepositoryAccountsAdapter {
    private let derivationIndex: Int
    private let walletManagersRepository: WalletManagersRepository

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
                // [REDACTED_TODO_COMMENT]
                guard let derivationPath = key.derivationPaths().first else {
                    // The absence of derivation paths means that this wallet manager belongs to the main account
                    return derivationIndex == CommonCryptoAccountsRepository.Constants.mainAccountDerivationIndex
                }

                let extractor = AccountDerivationNodeExtractor(blockchain: key.blockchain)
                let derivationNode = extractor.extract(from: derivationPath)

                // [REDACTED_TODO_COMMENT]
                return derivationNode.rawIndex == UInt32(derivationIndex)
            }
    }
}

// MARK: - WalletManagersRepository protocol conformance

extension WalletManagersRepositoryAccountsAdapter: WalletManagersRepository {
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

// MARK: - Constants

private extension WalletManagersRepositoryAccountsAdapter {
    enum Constants {
        static let utxoDerivationNodeIndex = 3
        static let nonUTXODerivationNodeIndex = 5
    }
}
