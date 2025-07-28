//
//  StartupProcessor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class StartupProcessor {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var shouldOpenAuthScreen: Bool {
        if FeatureProvider.isAvailable(.hotWallet) {
            AppSettings.shared.saveUserWallets
                && userWalletRepository.models.isNotEmpty
        } else {
            AppSettings.shared.saveUserWallets
                && userWalletRepository.models.isNotEmpty
                && BiometricsUtil.isAvailable
        }
    }

    func getStartupOption() -> StartupOption {
        if BackupHelper().hasIncompletedBackup {
            return .uncompletedBackup
        }

        if shouldOpenAuthScreen {
            return .auth
        }

        return .welcome
    }
}

enum StartupOption {
    case uncompletedBackup
    case auth
    case welcome
}
