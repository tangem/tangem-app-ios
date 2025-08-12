//
//  HotFinishActivationNeededViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class HotFinishActivationNeededViewModel {
    let title = Localization.hwActivationNeedTitle
    let description = Localization.hwActivationNeedDescription
    let laterTitle = Localization.commonLater
    let backupTitle = Localization.hwActivationNeedBackup

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
