//
//  MainHeaderSubtitleProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct MainHeaderSubtitleProviderFactory {
    func provider(for userWalletModel: UserWalletModel, isMultiWallet: Bool) -> MainHeaderSubtitleProvider {
        let isUserWalletLocked = userWalletModel.isUserWalletLocked

        if isMultiWallet {
            return MultiWalletMainHeaderSubtitleProvider(
                isUserWalletLocked: userWalletModel.isUserWalletLocked,
                areWalletsImported: userWalletModel.userWallet.card.wallets.contains(where: { $0.isImported ?? false }),
                dataSource: userWalletModel
            )
        }

        if userWalletModel.config is VisaConfig {
            return VisaWalletMainHeaderSubtitleProvider(
                isUserWalletLocked: isUserWalletLocked,
                dataSource: userWalletModel.walletModelsManager.walletModels.first { $0.isToken }
            )
        }

        return SingleWalletMainHeaderSubtitleProvider(
            isUserWalletLocked: isUserWalletLocked,
            dataSource: userWalletModel.walletModelsManager.walletModels.first
        )
    }
}
