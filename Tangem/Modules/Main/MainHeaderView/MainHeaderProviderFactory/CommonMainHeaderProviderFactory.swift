//
//  CommonMainHeaderProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonMainHeaderProviderFactory: MainHeaderProviderFactory {
    func makeHeaderBalanceProvider(for model: UserWalletModel) -> MainHeaderBalanceProvider {
        return CommonMainHeaderBalanceProvider(
            totalBalanceProvider: model,
            userWalletStateInfoProvider: model,
            mainBalanceFormatter: CommonMainHeaderBalanceFormatter()
        )
    }

    func makeHeaderSubtitleProvider(for userWalletModel: UserWalletModel, isMultiWallet: Bool) -> MainHeaderSubtitleProvider {
        let isUserWalletLocked = userWalletModel.isUserWalletLocked

        if isMultiWallet {
            return MultiWalletMainHeaderSubtitleProvider(
                isUserWalletLocked: userWalletModel.isUserWalletLocked,
                areWalletsImported: userWalletModel.keysRepository.keys.contains(where: { $0.isImported ?? false }),
                dataSource: userWalletModel
            )
        }

        return SingleWalletMainHeaderSubtitleProvider(
            isUserWalletLocked: isUserWalletLocked,
            dataSource: userWalletModel.walletModelsManager.walletModels.first
        )
    }
}
