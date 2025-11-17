//
//  TokenAdder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct TokenAdder {
    private let tokenFinder: TokenFinder

    init(tokenFinder: any TokenFinder) {
        self.tokenFinder = tokenFinder
    }

    func addToken(blockchainNetwork: BlockchainNetwork, contractAddress: String) async throws -> TokenItem {
        let tokenItem = try await tokenFinder.findToken(
            blockchainNetwork: blockchainNetwork,
            contractAddress: contractAddress
        )

        let userTokensManager = try userTokensManager(tokenItem: .blockchain(blockchainNetwork))
        try userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
        return tokenItem
    }

    func addToken(blockchainNetwork: BlockchainNetwork, token: BSDKToken) throws {
        let userTokensManager = try userTokensManager(tokenItem: .blockchain(blockchainNetwork))

        let tokenItem = TokenItem.token(token, blockchainNetwork)
        try userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
    }

    private func userTokensManager(tokenItem: TokenItem) throws -> any UserTokensManager {
        let walletModelResult = try WalletModelFinder().findWalletModel(tokenItem: tokenItem)

        let userTokensManager: (any UserTokensManager)? = if FeatureProvider.isAvailable(.accounts) {
            walletModelResult.walletModel.account?.userTokensManager
        } else {
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
        case userTokensManagerNotFound

        var errorDescription: String? {
            switch self {
            case .userTokensManagerNotFound: "UserTokensManager not found"
            }
        }
    }
}
