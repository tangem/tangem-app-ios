//
//  MainHeaderSubtitleProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct MainHeaderSubtitleProviderFactory {
    func provider(for userWalletModel: UserWalletModel) -> MainHeaderSubtitleProvider {
        guard userWalletModel.isMultiWallet else {
            return SingleWalletMainHeaderSubtitleProvider(userWalletModel: userWalletModel, walletModel: userWalletModel.walletModelsManager.walletModels.first)
        }

        return MultiWalletMainHeaderSubtitleProvider(userWalletModel: userWalletModel)
    }
}
