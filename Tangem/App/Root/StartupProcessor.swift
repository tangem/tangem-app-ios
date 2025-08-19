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

        if let modelToOpen = shouldOpenMainScreen() {
            return .main(modelToOpen)
        }

        if shouldOpenAuthScreen {
            return .auth
        }

        return .welcome
    }

    private func shouldOpenMainScreen() -> UserWalletModel? {
        guard FeatureProvider.isAvailable(.hotWallet) else {
            return nil
        }

        let allUnlocked = userWalletRepository.models.allConforms { !$0.isUserWalletLocked }
        guard allUnlocked else {
            return nil
        }

        if let selectedModel = userWalletRepository.selectedModel {
            return selectedModel
        }

        if let firstModel = userWalletRepository.models.first {
            return firstModel
        }

        return nil
    }
}

enum StartupOption {
    case uncompletedBackup
    case auth
    case welcome
    case main(UserWalletModel)
}
