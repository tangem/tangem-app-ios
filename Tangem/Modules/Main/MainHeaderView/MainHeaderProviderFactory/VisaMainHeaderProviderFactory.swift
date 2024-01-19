//
//  VisaMainHeaderProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct VisaMainHeaderProviderFactory: MainHeaderProviderFactory {
    func makeHeaderBalanceProvider(for model: UserWalletModel) -> MainHeaderBalanceProvider {
        guard let walletModel = model.walletModelsManager.walletModels.first(where: { $0.isToken }) else {
            return CommonMainHeaderBalanceProvider(
                totalBalanceProvider: model,
                userWalletStateInfoProvider: model,
                mainBalanceFormatter: CommonMainHeaderBalanceFormatter()
            )
        }

        return CommonMainHeaderBalanceProvider(
            totalBalanceProvider: SingleTokenTotalBalanceProvider(walletModel: walletModel, isFiat: false),
            userWalletStateInfoProvider: model,
            mainBalanceFormatter: VisaMainHeaderBalanceFormatter()
        )
    }

    func makeHeaderSubtitleProvider(for userWalletModel: UserWalletModel, isMultiWallet: Bool) -> MainHeaderSubtitleProvider {
        let isUserWalletLocked = userWalletModel.isUserWalletLocked

        return VisaWalletMainHeaderSubtitleProvider(
            isUserWalletLocked: isUserWalletLocked,
            dataSource: userWalletModel.walletModelsManager.walletModels.first { $0.isToken }
        )
    }
}
