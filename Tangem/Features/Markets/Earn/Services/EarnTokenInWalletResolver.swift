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
    /// - **More than one wallet or more than one account** → always `.toAdd` (show account selection / add flow).
    /// - **Exactly one wallet and one account**, token added → `.alreadyAdded` (navigate to token page).
    /// - **Exactly one wallet and one account**, token not added → `.toAdd`.
    func resolve(
        earnToken: EarnTokenModel,
        userWalletModels: [any UserWalletModel]
    ) -> EarnTokenResolution {
        guard let singleWallet = userWalletModels.singleElement else {
            return .toAdd(token: earnToken, userWalletModels: userWalletModels)
        }

        let manageableAccounts = manageableAccountsForEarnToken(earnToken, in: singleWallet)
        guard let singleAccount = manageableAccounts.singleElement else {
            return .toAdd(token: earnToken, userWalletModels: userWalletModels)
        }

        let networkModel = NetworkModel(
            networkId: earnToken.networkId,
            contractAddress: earnToken.contractAddress,
            decimalCount: earnToken.decimalCount
        )
        let supportedBlockchains = singleWallet.config.supportedBlockchains
        let tokenItemMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)
        guard let tokenItem = tokenItemMapper.mapToTokenItem(
            id: earnToken.id,
            name: earnToken.name,
            symbol: earnToken.symbol,
            network: networkModel
        ) else {
            return .toAdd(token: earnToken, userWalletModels: userWalletModels)
        }

        let containsToken = singleAccount.userTokensManager.contains(tokenItem, derivationInsensitive: false)
        guard containsToken,
              let walletModel = singleAccount.walletModelsManager.walletModels.first(where: { $0.tokenItem == tokenItem })
        else {
            return .toAdd(token: earnToken, userWalletModels: userWalletModels)
        }

        return .alreadyAdded(walletModel: walletModel, userWalletModel: singleWallet)
    }

    private func manageableAccountsForEarnToken(
        _ earnToken: EarnTokenModel,
        in userWalletModel: any UserWalletModel
    ) -> [any CryptoAccountModel] {
        let supportedBlockchains = userWalletModel.config.supportedBlockchains
        return userWalletModel.accountModelsManager.cryptoAccountModels.filter { cryptoAccount in
            AccountBlockchainManageabilityChecker.canManageNetwork(
                earnToken.networkId,
                for: cryptoAccount,
                in: supportedBlockchains
            )
        }
    }
}
