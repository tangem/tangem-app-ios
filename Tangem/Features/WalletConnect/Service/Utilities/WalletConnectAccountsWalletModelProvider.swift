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

        accountModelsManager
            .accountModelsPublisher
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
            let model = getMainWalletModels(for: accountId).first(where: {
                $0.tokenItem.blockchain.networkId == blockchainId
                    && $0.walletConnectAddress.caseInsensitiveCompare(address) == .orderedSame
            })
        else {
            throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
        }

        return model
    }

    func getModels(with blockchainId: String, accountId: String) -> [any WalletModel] {
        getMainWalletModels(for: accountId).filter { $0.tokenItem.blockchain.networkId == blockchainId }
    }

    func getModel(with blockchainId: String, accountId: String) -> (any WalletModel)? {
        getMainWalletModels(for: accountId).first { $0.tokenItem.blockchain.networkId == blockchainId }
    }

    private func getMainWalletModels(for accountId: String) -> [any WalletModel] {
        guard
            let cryptoAccountModel = WCAccountFinder.findCryptoAccountModel(
                by: accountId,
                accountModelsManager: accountModelsManager
            )
        else { return [] }

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
