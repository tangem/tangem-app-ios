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

        let walletModelResult = try WalletModelFinder.findWalletModel(tokenItem: .blockchain(blockchainNetwork))
        let userTokensManager = try userTokensManager(walletModelResult: walletModelResult)
        try userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
        return tokenItem
    }

    func addToken(defaultAddress: String, token: BSDKToken) throws {
        let walletModelResult = try WalletModelFinder.findMainWalletModel(defaultAddress: defaultAddress)
        let userTokensManager = try userTokensManager(walletModelResult: walletModelResult)

        let targetBlockchainNetwork = walletModelResult.walletModel.tokenItem.blockchainNetwork
        let tokenItem = TokenItem.token(token, targetBlockchainNetwork)
        try userTokensManager.update(itemsToRemove: [], itemsToAdd: [tokenItem])
    }
}

// MARK: - Private

private extension TokenAdder {
    func userTokensManager(walletModelResult: WalletModelFinder.Result) throws -> any UserTokensManager {
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
