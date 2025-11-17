//
//  WalletConnectAccountsWalletModelProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol WalletConnectAccountsWalletModelProvider {
    /// This info is based on information from WC and they didn't know anything about derivation
    /// So we need to compare blockchain and address to simulate comparision of derivation path
    /// Information about address is encoded in request params and info about blockchain - request chainId
    func getModel(
        with address: String,
        blockchainId: String,
        accountId: String
    ) throws -> any WalletModel

    func getModels(with blockchainId: String, accountId: String) -> [any WalletModel]

    func getModel(with blockchainId: String, accountId: String) -> (any WalletModel)?
}

final class CommonWalletConnectAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider {
    private let accountModelsManager: AccountModelsManager

    private var accountModels: [AccountModel] = []

    private var bag: Set<AnyCancellable> = []

    init(accountModelsManager: AccountModelsManager) {
        self.accountModelsManager = accountModelsManager

        accountModelsManager.accountModelsPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, accounts in
                viewModel.accountModels = accounts
            }
            .store(in: &bag)
    }

    func getModel(
        with address: String,
        blockchainId: String,
        accountId: String
    ) throws -> any WalletModel {
        guard
            let model = getMainWalletModel(for: accountId).first(where: {
                $0.tokenItem.blockchain.networkId == blockchainId
                    && $0.defaultAddressString.caseInsensitiveCompare(address) == .orderedSame
            })
        else {
            throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
        }

        return model
    }

    func getModels(with blockchainId: String, accountId: String) -> [any WalletModel] {
        getMainWalletModel(for: accountId).filter { $0.tokenItem.blockchain.networkId == blockchainId }
    }

    func getModel(with blockchainId: String, accountId: String) -> (any WalletModel)? {
        getMainWalletModel(for: accountId).first { $0.tokenItem.blockchain.networkId == blockchainId }
    }

    private func getMainWalletModel(for accountId: String) -> [any WalletModel] {
        guard let cryptoAccountModel = accountModelsManager.findCryptoAccountModel(by: accountId) else { return [] }

        return cryptoAccountModel.walletModelsManager.walletModels.filter { $0.isMainToken }
    }
}

struct NotSupportedWalletConnectAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider {
    func getModel(
        with address: String,
        blockchainId: String,
        accountId: String
    ) throws -> any WalletModel {
        throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
    }

    func getModels(with blockchainId: String, accountId: String) -> [any WalletModel] {
        []
    }

    func getModel(with blockchainId: String, accountId: String) -> (any WalletModel)? {
        nil
    }
}

// MARK: - Convenience extensions

private extension AccountModelsManager {
    func findCryptoAccountModel(by accountId: String) -> (any CryptoAccountModel)? {
        for accountModel in accountModels {
            switch accountModel {
            case .standard(let cryptoAccounts):
                switch cryptoAccounts {
                case .single(let cryptoAccountModel):
                    if cryptoAccountModel.id.walletConnectIdentifierString == accountId {
                        return cryptoAccountModel
                    }
                case .multiple(let cryptoAccountModels):
                    if let cryptoAccountModel = cryptoAccountModels.first(where: {
                        $0.id.walletConnectIdentifierString == accountId
                    }) {
                        return cryptoAccountModel
                    }
                }
            }
        }

        return nil
    }
}
