//
//  CommonWalletConnectWalletModelProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol WalletConnectWalletModelProvider {
    /// This info is based on information from WC and they didn't know anything about derivation
    /// So we need to compare blockchain and address to simulate comparision of derivation path
    /// Information about address is encoded in request params and info about blockchain - request chainId
    func getModel(with address: String, blockchainId: String) throws -> any WalletModel

    func getModels(with blockchainId: String) -> [any WalletModel]

    func getModel(with blockchainId: String) -> (any WalletModel)?
}

struct CommonWalletConnectWalletModelProvider: WalletConnectWalletModelProvider {
    private let walletModelsManager: WalletModelsManager

    private var mainWalletModels: [any WalletModel] {
        walletModelsManager.walletModels.filter {
            $0.isMainToken
        }
    }

    init(walletModelsManager: WalletModelsManager) {
        self.walletModelsManager = walletModelsManager
    }

    func getModel(with address: String, blockchainId: String) throws -> any WalletModel {
        guard
            let model = mainWalletModels.first(where: {
                $0.tokenItem.blockchain.networkId == blockchainId
                    && $0.walletConnectAddress.caseInsensitiveCompare(address) == .orderedSame
            })
        else {
            throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
        }

        return model
    }

    func getModels(with blockchainId: String) -> [any WalletModel] {
        return mainWalletModels.filter { $0.tokenItem.blockchain.networkId == blockchainId }
    }

    func getModel(with blockchainId: String) -> (any WalletModel)? {
        mainWalletModels.first { $0.tokenItem.blockchain.networkId == blockchainId }
    }
}

struct NotSupportedWalletConnectWalletModelProvider: WalletConnectWalletModelProvider {
    func getModel(with address: String, blockchainId: String) throws -> any WalletModel {
        throw WalletConnectTransactionRequestProcessingError.walletModelNotFound(blockchainNetworkID: blockchainId)
    }

    func getModels(with blockchainId: String) -> [any WalletModel] {
        return []
    }

    func getModel(with blockchainId: String) -> (any WalletModel)? {
        return nil
    }
}
