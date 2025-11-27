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
    @Injected(\.servicesManager) private var servicesManager: ServicesManager

    var shouldOpenAuthScreen: Bool {
        if MobileWalletFeatureProvider.isAvailable {
            AppSettings.shared.saveUserWallets
                && userWalletRepository.models.isNotEmpty
        } else {
            AppSettings.shared.saveUserWallets
                && userWalletRepository.models.isNotEmpty
                && BiometricsUtil.isAvailable
        }
    }

    func getStartupOption() -> StartupOption {
        guard servicesManager.initialized else {
            return .launchScreen
        }

        if BackupHelper().hasIncompletedBackup {
            return .uncompletedBackup
        }

        if let modelToOpen = shouldOpenMainScreen() {
            SignInAnalyticsLogger().logSignInEvent(signInType: .noSecurity)
            return .main(modelToOpen)
        }

        if shouldOpenAuthScreen {
            return .auth
        }

        return .welcome
    }

    private func shouldOpenMainScreen() -> UserWalletModel? {
        guard MobileWalletFeatureProvider.isAvailable else {
            return nil
        }

        let allUnlocked = userWalletRepository.models.allConforms { !$0.isUserWalletLocked }
        guard allUnlocked else {
            return nil
        }

        if let selectedModel = userWalletRepository.selectedModel {
            return selectedModel
        }

        return nil
    }
}

enum StartupOption {
    case uncompletedBackup
    case auth
    case welcome
    case main(UserWalletModel)
    case launchScreen
}
