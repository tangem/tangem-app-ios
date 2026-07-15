//
//  WalletConnectAccountsWalletModelProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol WalletConnectAccountsWalletModelProvider {
    /// This info is based on information from WC and they didn't know anything about derivation
    /// So we need to compare blockchain and address to simulate comparison of derivation path
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
    private let addressComparisonHelper = AddressComparisonHelper()

    private var allMainWalletModels: [any WalletModel] = []

    private var bag: Set<AnyCancellable> = []

    init(accountModelsManager: AccountModelsManager) {
        self.accountModelsManager = accountModelsManager
        allMainWalletModels = makeMainWalletModels(from: accountModelsManager.accountModels)

        accountModelsManager
            .accountModelsPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, accounts in
                viewModel.allMainWalletModels = viewModel.makeMainWalletModels(from: accounts)
            }
            .store(in: &bag)
    }

    func getModel(
        with address: String,
        blockchainId: String,
        accountId: String
    ) throws -> any WalletModel {
        let modelsInAccount = getMainWalletModels(for: accountId)

        if let model = modelsInAccount.first(where: {
            $0.tokenItem.blockchain.networkId == blockchainId
                && matches(model: $0, address: address)
        }) {
            return model
        }

        if shouldUseFallback(accountId: accountId),
           let fallbackModel = getMainWalletModelsFromAllAccounts().first(where: {
               $0.tokenItem.blockchain.networkId == blockchainId
                   && matches(model: $0, address: address)
           }) {
            return fallbackModel
        }

        throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
    }

    func getModels(with blockchainId: String, accountId: String) -> [any WalletModel] {
        let modelsInAccount = getMainWalletModels(for: accountId).filter { $0.tokenItem.blockchain.networkId == blockchainId }

        if modelsInAccount.isNotEmpty {
            return modelsInAccount
        }

        guard shouldUseFallback(accountId: accountId) else {
            return []
        }

        return getMainWalletModelsFromAllAccounts().filter { $0.tokenItem.blockchain.networkId == blockchainId }
    }

    func getModel(with blockchainId: String, accountId: String) -> (any WalletModel)? {
        if let model = getMainWalletModels(for: accountId).first(where: { $0.tokenItem.blockchain.networkId == blockchainId }) {
            return model
        }

        guard shouldUseFallback(accountId: accountId) else {
            return nil
        }

        return getMainWalletModelsFromAllAccounts().first { $0.tokenItem.blockchain.networkId == blockchainId }
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

    private func getMainWalletModelsFromAllAccounts() -> [any WalletModel] {
        allMainWalletModels
    }

    private func makeMainWalletModels(from accountModels: [AccountModel]) -> [any WalletModel] {
        accountModels.flatMap { accountModel in
            allCryptoAccounts(from: accountModel).flatMap { cryptoAccount in
                cryptoAccount.walletModelsManager.walletModels.filter(\.isMainToken)
            }
        }
    }

    private func allCryptoAccounts(from accountModel: AccountModel) -> [any CryptoAccountModel] {
        switch accountModel {
        case .standard(.single(let cryptoAccount)):
            return [cryptoAccount]
        case .standard(.multiple(let cryptoAccounts)):
            return cryptoAccounts
        case .tangemPay:
            return []
        }
    }

    private func shouldUseFallback(accountId: String) -> Bool {
        accountId.isEmpty
    }

    private func matches(model: any WalletModel, address: String) -> Bool {
        let blockchain = model.tokenItem.blockchain

        if addressComparisonHelper.matches(lhs: model.walletConnectAddress, rhs: address, blockchain: blockchain) {
            return true
        }

        return addressComparisonHelper.matchesAnyAddress(addresses: model.addressesString, address: address, blockchain: blockchain)
    }
}

extension CommonWalletConnectAccountsWalletModelProvider {
    struct AddressComparisonHelper {
        let addressComparator = AddressComparator()

        func matches(lhs: String, rhs: String, blockchain: Blockchain) -> Bool {
            addressComparator.addressesMatch(lhs, rhs, blockchain: blockchain)
        }

        func matchesAnyAddress(addresses: [String], address: String, blockchain: Blockchain) -> Bool {
            addresses.contains { addressComparator.addressesMatch($0, address, blockchain: blockchain) }
        }
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
