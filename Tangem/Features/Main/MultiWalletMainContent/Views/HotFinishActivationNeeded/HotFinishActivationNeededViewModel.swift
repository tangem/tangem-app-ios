//
//  HotFinishActivationNeededViewModel.swift
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

final class HotFinishActivationNeededViewModel {
    var description: String {
        isBackupNeeded ? Localization.hwActivationNeedDescription : Localization.hwActivationNeedWarningDescription
    }

    var iconType: ImageType {
        hasPositiveBalance ? Assets.criticalAttentionShield : Assets.attentionShield
    }

    var iconBgColor: Color {
        hasPositiveBalance ? Colors.Icon.warning : Colors.Icon.attention
    }

    let title = Localization.hwActivationNeedTitle
    let laterTitle = Localization.commonLater
    let backupTitle = Localization.hwActivationNeedBackup

    private var isBackupNeeded: Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup) && userWalletModel.config.hasFeature(.iCloudBackup)
    }

    private var hasPositiveBalance: Bool {
        userWalletModel.totalBalance.hasPositiveBalance
    }

    private let userWalletModel: UserWalletModel
    private weak var routable: HotFinishActivationNeededRoutable?

    init(userWalletModel: UserWalletModel, routable: HotFinishActivationNeededRoutable) {
        self.userWalletModel = userWalletModel
        self.routable = routable
    }
}

// MARK: - Internal methods

extension HotFinishActivationNeededViewModel {
    func onCloseTap() {
        routable?.dismissHotFinishActivationNeeded()
    }

    func onLaterTap() {
        routable?.dismissHotFinishActivationNeeded()
    }

    func onBackupTap() {
        routable?.dismissHotFinishActivationNeeded()
        routable?.openHotBackupOnboarding(userWalletModel: userWalletModel)
    }
}

// MARK: - FloatingSheetContentViewModel

extension HotFinishActivationNeededViewModel: FloatingSheetContentViewModel {}
