//
//  UserWalletFinder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct UserWalletFinder {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func addToken(_ token: Token, in blockchain: Blockchain, for address: String) {
        guard let result = find(token, in: blockchain, with: address) else { return }

        do {
            let userWalletModel = result.userWalletModel
            let tokenItem = result.tokenItem

            try userWalletModel.userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
        } catch {
            AppLogger.error("Failed to add token after transaction to other wallet", error: error)
        }
    }

    private func find(_ token: Token, in blockchain: Blockchain, with address: String) -> SearchResult? {
        for userWalletModel in userWalletRepository.models {
            let walletModels = userWalletModel.walletModelsManager.walletModels

            guard let walletModel = walletModels.first(where: {
                $0.isMainToken &&
                    $0.tokenItem.blockchain == blockchain &&
                    $0.defaultAddress == address
            }) else {
                continue
            }

            let tokenItem = TokenItem.token(token, walletModel.tokenItem.blockchainNetwork)

            if walletModels.contains(where: { $0.tokenItem == tokenItem }) {
                return nil
            } else {
                return SearchResult(userWalletModel: userWalletModel, tokenItem: tokenItem)
            }
        }

        return nil
    }
}

private extension UserWalletFinder {
    struct SearchResult {
        let userWalletModel: UserWalletModel
        let tokenItem: TokenItem
    }
}
