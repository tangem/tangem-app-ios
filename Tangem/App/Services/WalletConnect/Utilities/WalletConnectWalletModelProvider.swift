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
    func getModel(with address: String, in blockchain: Blockchain) throws -> WalletModel
}

struct CommonWalletConnectWalletModelProvider: WalletConnectWalletModelProvider {
    private let userWallet: UserWalletModel

    init(userWallet: UserWalletModel) {
        self.userWallet = userWallet
    }

    func getModel(with address: String, in blockchain: Blockchain) throws -> WalletModel {
        guard
            let model = userWallet.walletModelsManager.walletModels.first(where: {
                $0.wallet.blockchain == blockchain && $0.wallet.address.caseInsensitiveCompare(address) == .orderedSame
            })
        else {
            throw WalletConnectV2Error.walletModelNotFound(blockchain)
        }

        return model
    }
}
