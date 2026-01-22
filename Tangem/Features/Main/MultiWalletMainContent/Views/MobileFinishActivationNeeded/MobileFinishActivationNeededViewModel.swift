//
//  MobileFinishActivationNeededViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemLocalization
import TangemAssets
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileFinishActivationNeededViewModel {
    var description: String {
        isBackupNeeded ? Localization.hwActivationNeedDescription : Localization.hwActivationNeedWarningDescription
    }

    var iconType: ImageType {
        Assets.criticalAttentionShield
    }

    var iconBgColor: Color {
        Colors.Icon.warning
    }

    let title = Localization.hwActivationNeedTitle
    let laterTitle = Localization.commonLater
    let backupTitle = Localization.hwActivationNeedBackup

    private var isBackupNeeded: Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup) && userWalletModel.config.hasFeature(.iCloudBackup)
    }

    private let userWalletModel: UserWalletModel
    private weak var coordinator: MobileFinishActivationNeededRoutable?

    init(userWalletModel: UserWalletModel, coordinator: MobileFinishActivationNeededRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension MobileFinishActivationNeededViewModel {
    func onCloseTap() {
        Analytics.log(.backupSkipped)
        coordinator?.dismissMobileFinishActivationNeeded()
    }

    func onLaterTap() {
        Analytics.log(.backupSkipped)
        coordinator?.dismissMobileFinishActivationNeeded()
    }

    func onBackupTap() {
        Analytics.log(.backupStarted)
        coordinator?.dismissMobileFinishActivationNeeded()

        if isBackupNeeded {
            coordinator?.openMobileBackup(userWalletModel: userWalletModel)
        } else {
            coordinator?.openMobileBackupOnboarding(userWalletModel: userWalletModel)
        }
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileFinishActivationNeededViewModel: FloatingSheetContentViewModel {}
