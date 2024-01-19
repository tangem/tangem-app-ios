//
//  MainHeaderBalanceProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct MainHeaderBalanceProviderFactory {
    func provider(for model: UserWalletModel) -> MainHeaderBalanceProvider {
        if model.config is VisaConfig,
           let walletModel = model.walletModelsManager.walletModels.first(where: { $0.isToken }) {
            return CommonMainHeaderBalanceProvider(
                totalBalanceProvider: SingleTokenTotalBalanceProvider(walletModel: walletModel, isFiat: false),
                userWalletStateInfoProvider: model,
                mainBalanceFormatter: VisaMainHeaderBalanceFormatter()
            )
        }

        return CommonMainHeaderBalanceProvider(
            totalBalanceProvider: model,
            userWalletStateInfoProvider: model,
            mainBalanceFormatter: CommonMainHeaderBalanceFormatter()
        )
    }
}
