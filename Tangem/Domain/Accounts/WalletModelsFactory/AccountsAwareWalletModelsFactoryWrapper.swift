//
//  AccountsAwareWalletModelsFactoryWrapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

/// The sole purpose of this wrapper is to inject a `CryptoAccountModel` into `WalletModel`s created by [REDACTED_AUTHOR]
/// This can't be done during the initialization of these models due to the complexity of the domain and circular dependencies.
final class AccountsAwareWalletModelsFactoryWrapper {
    private let innerFactory: WalletModelsFactory
    private weak var cryptoAccount: (any CryptoAccountModel)?

    init(innerFactory: any WalletModelsFactory) {
        self.innerFactory = innerFactory
    }

    private func enrichWalletModels(_ walletModels: [any WalletModel]) {
        guard let cryptoAccount else {
            preconditionFailure("Crypto account is not set for AccountsAwareWalletModelsFactoryWrapper")
        }

        let resolver = Resolver(cryptoAccount: cryptoAccount)
        walletModels.forEach { $0.resolve(using: resolver) }
    }
}

// MARK: - WalletModelsFactory protocol conformance

extension AccountsAwareWalletModelsFactoryWrapper: WalletModelsFactory {
    func makeWalletModels(
        for types: [Amount.AmountType],
        walletManager: WalletManager,
        blockchainNetwork: BlockchainNetwork,
        targetAccountDerivationPath: DerivationPath?
    ) -> [any WalletModel] {
        let walletModels = innerFactory.makeWalletModels(
            for: types,
            walletManager: walletManager,
            blockchainNetwork: blockchainNetwork,
            targetAccountDerivationPath: targetAccountDerivationPath
        )
        enrichWalletModels(walletModels)

        return walletModels
    }
}

// MARK: - AccountsAwareWalletModelsFactoryInput protocol conformance

extension AccountsAwareWalletModelsFactoryWrapper: AccountsAwareWalletModelsFactoryInput {
    func setCryptoAccount(_ cryptoAccount: any CryptoAccountModel) {
        self.cryptoAccount = cryptoAccount
    }
}

// MARK: - Auxiliary types

private extension AccountsAwareWalletModelsFactoryWrapper {
    struct Resolver: WalletModelResolving {
        let cryptoAccount: any CryptoAccountModel

        func resolve(walletModel: CommonWalletModel) {
            walletModel.setCryptoAccount(cryptoAccount)
        }

        func resolve(walletModel: NFTSendWalletModelProxy) {
            // No-op, this wallet model type is just a proxy for an underlying `WalletModel`,
            // which already has its crypto account set
        }

        func resolve(walletModel: VisaWalletModel) {
            // No-op, visa wallet model does not belong to crypto account
        }
    }
}
