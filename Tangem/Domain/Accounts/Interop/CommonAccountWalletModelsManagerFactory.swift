//
//  CommonAccountWalletModelsManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonAccountWalletModelsManagerFactory {
    private let walletManagersRepository: WalletManagersRepository
    private let walletModelsFactory: WalletModelsFactory

    init(
        walletManagersRepository: WalletManagersRepository,
        walletModelsFactory: WalletModelsFactory
    ) {
        self.walletManagersRepository = walletManagersRepository
        self.walletModelsFactory = walletModelsFactory
    }
}

// MARK: - AccountWalletModelsManagerFactory protocol conformance

extension CommonAccountWalletModelsManagerFactory: AccountWalletModelsManagerFactory {
    func makeWalletModelsManager(forAccountWithDerivationIndex derivationIndex: Int) -> WalletModelsManager {
        let repositoryAdapter = AccountWalletManagersRepositoryAdapter(
            derivationIndex: derivationIndex,
            walletManagersRepository: walletManagersRepository
        )

        return CommonWalletModelsManager(
            walletManagersRepository: repositoryAdapter,
            walletModelsFactory: walletModelsFactory
        )
    }
}
