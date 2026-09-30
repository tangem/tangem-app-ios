//
//  TokenAdder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

enum TokenAdder {
    static func addToken(tokenItem: TokenItem, userWalletId: UserWalletId) throws {
        guard tokenItem.isToken else {
            assertionFailure("Supports only tokens. TokenItem.blockchain item may require derivation")
            throw Error.onlyTokensSupported
        }

        let blockchainNetwork = tokenItem.blockchainNetwork
        // Scope the lookup to the source wallet: several wallets can share the same derivation path,
        // and an unscoped `findWalletModel(tokenItem:)` would add the token to whichever wallet is
        // found first, i.e. potentially the wrong one.
        let walletModelResult = try WalletModelFinder.findWalletModel(userWalletId: userWalletId, tokenItem: .blockchain(blockchainNetwork))
        let userTokensManager = try userTokensManager(walletModelResult: walletModelResult)
        try userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
    }

    static func addToken(_ token: BSDKToken, to address: String, in blockchain: Blockchain) throws {
        let walletModelResult = try WalletModelFinder.findMainWalletModel(
            address: address,
            networkId: blockchain.networkId,
            isTestnet: blockchain.isTestnet
        )
        let userTokensManager = try userTokensManager(walletModelResult: walletModelResult)

        let targetBlockchainNetwork = walletModelResult.walletModel.tokenItem.blockchainNetwork
        let tokenItem = TokenItem.token(token, targetBlockchainNetwork)
        try userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
    }
}

// MARK: - Private

private extension TokenAdder {
    static func userTokensManager(walletModelResult: WalletModelFinder.Result) throws -> any UserTokensManager {
        guard let userTokensManager = walletModelResult.walletModel.account?.userTokensManager else {
            throw Error.userTokensManagerNotFound
        }

        return userTokensManager
    }
}

extension TokenAdder {
    enum Error: LocalizedError {
        case onlyTokensSupported
        case userTokensManagerNotFound

        var errorDescription: String? {
            switch self {
            case .onlyTokensSupported: "TokenAdder supports only token's adding"
            case .userTokensManagerNotFound: "UserTokensManager not found"
            }
        }
    }
}
