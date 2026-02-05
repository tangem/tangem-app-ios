//
//  TokenAdder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum TokenAdder {
    static func addToken(tokenItem: TokenItem) throws {
        guard tokenItem.isToken else {
            assertionFailure("Supports only tokens. TokenItem.blockchain item may require derivation")
            throw Error.onlyTokensSupported
        }

        let blockchainNetwork = tokenItem.blockchainNetwork
        let walletModelResult = try WalletModelFinder.findWalletModel(tokenItem: .blockchain(blockchainNetwork))
        let userTokensManager = try userTokensManager(walletModelResult: walletModelResult)
        try userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
    }

    static func addToken(defaultAddress: String, token: BSDKToken) throws {
        let walletModelResult = try WalletModelFinder.findMainWalletModel(defaultAddress: defaultAddress)
        let userTokensManager = try userTokensManager(walletModelResult: walletModelResult)

        let targetBlockchainNetwork = walletModelResult.walletModel.tokenItem.blockchainNetwork
        let tokenItem = TokenItem.token(token, targetBlockchainNetwork)
        try userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
    }
}

// MARK: - Private

private extension TokenAdder {
    static func userTokensManager(walletModelResult: WalletModelFinder.Result) throws -> any UserTokensManager {
        let userTokensManager: (any UserTokensManager)? = if FeatureProvider.isAvailable(.accounts) {
            walletModelResult.walletModel.account?.userTokensManager
        } else {
            // accounts_fixes_needed_none
            walletModelResult.userWalletModel.userTokensManager
        }

        guard let userTokensManager else {
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
