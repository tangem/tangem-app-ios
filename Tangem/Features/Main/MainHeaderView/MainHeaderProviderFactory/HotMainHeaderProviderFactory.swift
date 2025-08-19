//
//  HotMainHeaderProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HotMainHeaderProviderFactory: MainHeaderProviderFactory {
    func makeHeaderBalanceProvider(for model: UserWalletModel) -> MainHeaderBalanceProvider {
        return CommonMainHeaderBalanceProvider(
            totalBalanceProvider: model,
            userWalletStateInfoProvider: model,
            mainBalanceFormatter: CommonMainHeaderBalanceFormatter()
        )
    }

    func makeHeaderSubtitleProvider(for userWalletModel: UserWalletModel, isMultiWallet: Bool) -> MainHeaderSubtitleProvider {
        let isBackupNeeded = userWalletModel.config.hasFeature(.mnemonicBackup) && userWalletModel.config.hasFeature(.iCloudBackup)
        return HotMainHeaderSubtitleProvider(
            isUserWalletLocked: userWalletModel.isUserWalletLocked,
            isBackupNeeded: isBackupNeeded,
            updatePublisher: userWalletModel.updatePublisher
        )
    }
}
