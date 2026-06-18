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
        CommonMainHeaderBalanceProvider(
            totalBalanceProvider: model,
            userWalletStateInfoProvider: model,
            mainBalanceFormatter: MainHeaderBalanceFormatter()
        )
    }

    func makeHeaderSubtitleProvider(for userWalletModel: UserWalletModel, isMultiWallet: Bool) -> MainHeaderSubtitleProvider {
        let isUserWalletLocked = userWalletModel.isUserWalletLocked

        if isMultiWallet {
            return MultiWalletMainHeaderSubtitleProvider(
                isUserWalletLocked: userWalletModel.isUserWalletLocked,
                dataSource: userWalletModel
            )
        }

        let balanceProvider = AccountWalletModelsAggregator
            .walletModels(from: userWalletModel.accountModelsManager)
            .first
            .map(\.totalTokenBalanceProvider)

        return SingleWalletMainHeaderSubtitleProvider(
            isUserWalletLocked: isUserWalletLocked,
            balanceProvider: balanceProvider
        )
    }
}
