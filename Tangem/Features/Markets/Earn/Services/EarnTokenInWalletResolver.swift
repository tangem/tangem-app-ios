//
//  EarnTokenInWalletResolver.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

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
    /// - Returns: `.alreadyAdded` if token exists in one of the wallets, `.toAdd` otherwise.
    func resolve(
        earnToken: EarnTokenModel,
        userWalletModels: [any UserWalletModel]
    ) -> EarnTokenResolution {
        let networkModel = NetworkModel(
            networkId: earnToken.networkId,
            contractAddress: earnToken.contractAddress,
            decimalCount: earnToken.decimalCount
        )

        for userWalletModel in userWalletModels {
            let supportedBlockchains = userWalletModel.config.supportedBlockchains
            let tokenItemMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)
            guard let tokenItem = tokenItemMapper.mapToTokenItem(
                id: earnToken.id,
                name: earnToken.name,
                symbol: earnToken.symbol,
                network: networkModel
            ) else {
                continue
            }

            for cryptoAccount in userWalletModel.accountModelsManager.cryptoAccountModels {
                guard AccountBlockchainManageabilityChecker.canManageNetwork(
                    earnToken.networkId,
                    for: cryptoAccount,
                    in: supportedBlockchains
                ) else {
                    continue
                }
                guard cryptoAccount.userTokensManager.contains(tokenItem, derivationInsensitive: false) else {
                    continue
                }

                if let walletModel = cryptoAccount.walletModelsManager.walletModels.first(where: { $0.tokenItem == tokenItem }) {
                    return .alreadyAdded(walletModel: walletModel, userWalletModel: userWalletModel)
                }
            }
        }

        return .toAdd(token: earnToken, userWalletModels: userWalletModels)
    }
}
