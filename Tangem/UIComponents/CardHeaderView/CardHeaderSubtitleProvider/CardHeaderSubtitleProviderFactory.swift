//
//  CardHeaderSubtitleProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CardHeaderSubtitleProviderFactory {
    func provider(for userWalletModel: UserWalletModel) -> CardHeaderSubtitleProvider {
        guard userWalletModel.isMultiWallet else {
            return SingleWalletCardHeaderSubtitleProvider(userWalletModel: userWalletModel, walletModel: userWalletModel.walletModelsManager.walletModels.first)
        }

        return MultiWalletCardHeaderSubtitleProvider(userWalletModel: userWalletModel)
    }
}
