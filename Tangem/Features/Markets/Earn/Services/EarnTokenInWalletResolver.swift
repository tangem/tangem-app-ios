//
//  EarnTokenInWalletResolver.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

// MARK: - EarnTokenResolution

enum EarnTokenResolution {
    /// Token is not in any wallet; show add token flow.
    case toAdd(token: EarnTokenModel, userWalletModels: [any UserWalletModel])
    /// Token is already in a wallet; open token details.
    case alreadyAdded(walletModel: any WalletModel, userWalletModel: any UserWalletModel)
}

// MARK: - EarnTokenInWalletResolver

struct EarnTokenInWalletResolver {
    /// Resolves earn token against user wallets.
    /// - **Not exactly one wallet and one account** (by `OneAndOnlyAccountFinder`) → `.toAdd` (add flow shows account selector).
    /// - **Exactly one wallet and one account**: token already added → `.alreadyAdded`; not added → `.toAdd` (add flow skips account selector).
    func resolve(
        earnToken: EarnTokenModel,
        userWalletModels: [any UserWalletModel]
    ) -> EarnTokenResolution {
        guard let oneAndOnly = OneAndOnlyAccountFinder.find(in: userWalletModels) else {
            return .toAdd(token: earnToken, userWalletModels: userWalletModels)
        }

        return resolveForSingleAccount(
            earnToken: earnToken,
            userWalletModel: oneAndOnly.userWalletModel,
            cryptoAccountModel: oneAndOnly.cryptoAccountModel
        )
    }

    private func resolveForSingleAccount(
        earnToken: EarnTokenModel,
        userWalletModel: any UserWalletModel,
        cryptoAccountModel: any CryptoAccountModel
    ) -> EarnTokenResolution {
        guard AccountBlockchainManageabilityChecker.canManageNetwork(
            earnToken.networkId,
            for: cryptoAccountModel,
            in: userWalletModel.config.supportedBlockchains
        ) else {
            return .toAdd(token: earnToken, userWalletModels: [userWalletModel])
        }

        guard let tokenItem = mapEarnTokenToTokenItem(
            earnToken,
            supportedBlockchains: userWalletModel.config.supportedBlockchains
        ) else {
            return .toAdd(token: earnToken, userWalletModels: [userWalletModel])
        }

        guard let walletModel = EarnWalletModelFinder.findWalletModel(
            for: tokenItem,
            in: cryptoAccountModel
        ) else {
            return .toAdd(token: earnToken, userWalletModels: [userWalletModel])
        }

        return .alreadyAdded(walletModel: walletModel, userWalletModel: userWalletModel)
    }

    private func mapEarnTokenToTokenItem(
        _ earnToken: EarnTokenModel,
        supportedBlockchains: Set<Blockchain>
    ) -> TokenItem? {
        let networkModel = NetworkModel(
            networkId: earnToken.networkId,
            contractAddress: earnToken.contractAddress,
            decimalCount: earnToken.decimalCount
        )
        let tokenItemMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)
        return tokenItemMapper.mapToTokenItem(
            id: earnToken.id,
            name: earnToken.name,
            symbol: earnToken.symbol,
            network: networkModel
        )
    }
}
