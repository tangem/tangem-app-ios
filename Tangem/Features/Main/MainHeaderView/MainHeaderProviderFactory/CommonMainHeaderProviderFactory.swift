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
                areWalletsImported: userWalletModel.hasImportedWallets,
                dataSource: userWalletModel
            )
        }

        // accounts_fixes_needed_main
        return SingleWalletMainHeaderSubtitleProvider(
            isUserWalletLocked: isUserWalletLocked,
            balanceProvider: userWalletModel.walletModelsManager.walletModels.first.map { $0.totalTokenBalanceProvider }
        )
    }
}
