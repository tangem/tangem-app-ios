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
    // This info is based on information from WC and they didn't know anything about derivation
    // So we need to compare blockchain and address to simulate comparision of derivation path
    // Information about address is encoded in request params and info about blockchain - request chainId
    func getModel(with address: String, in blockchain: Blockchain) throws -> WalletModel
}

struct CommonWalletConnectWalletModelProvider: WalletConnectWalletModelProvider {
    private let walletModelsManager: WalletModelsManager

    init(walletModelsManager: WalletModelsManager) {
        self.walletModelsManager = walletModelsManager
    }

    func getModel(with address: String, in blockchain: Blockchain) throws -> WalletModel {
        guard
            let model = walletModelsManager.walletModels.first(where: {
                $0.wallet.blockchain == blockchain && $0.wallet.address.caseInsensitiveCompare(address) == .orderedSame
            })
        else {
            throw WalletConnectV2Error.walletModelNotFound(blockchain)
        }

        return model
    }
}
