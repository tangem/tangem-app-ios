//
//  HotFinishActivationNeedViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class HotFinishActivationNeedViewModel {
    let title = Localization.hwActivationNeedTitle
    let description = Localization.hwActivationNeedDescription
    let laterTitle = Localization.commonLater
    let backupTitle = Localization.hwActivationNeedBackup

    private weak var routable: HotFinishActivationNeedRoutable?

    init(routable: HotFinishActivationNeedRoutable) {
        self.routable = routable
    }
}

// MARK: - Internal methods

extension HotFinishActivationNeedViewModel {
    func onCloseTap() {
        routable?.dismissHotFinishActivationNeed()
    }

    func onLaterTap() {
        routable?.dismissHotFinishActivationNeed()
    }

    func onBackupTap() {
        routable?.dismissHotFinishActivationNeed()
        routable?.openHotBackupOnboarding()
    }
}

// MARK: - FloatingSheetContentViewModel

extension HotFinishActivationNeedViewModel: FloatingSheetContentViewModel {}
