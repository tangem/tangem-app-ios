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

    private let jailbreakWarningUtil = JailbreakWarningUtil()

    var shouldOpenAuthScreen: Bool {
        AppSettings.shared.saveUserWallets && userWalletRepository.models.isNotEmpty
    }

    func getStartupOption() -> StartupOption {
        if jailbreakWarningUtil.shouldShowWarning() {
            return .jailbreakWarning
        }

        guard servicesManager.initialized else {
            return .launchScreen
        }

        if BackupHelper().hasIncompletedBackup {
            return .uncompletedBackup
        }

        if let modelToOpen = shouldOpenMainScreen() {
            SignInAnalyticsLogger().logSignInEvent(signInType: .noSecurity, userWalletModel: modelToOpen)
            return .main(modelToOpen)
        }

        if shouldOpenAuthScreen {
            return .auth
        }

        return .welcome
    }

    private func shouldOpenMainScreen() -> UserWalletModel? {
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
    case jailbreakWarning
}
