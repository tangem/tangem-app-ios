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

    private weak var routable: HotFinishActivationNeededRoutable?

    init(routable: HotFinishActivationNeededRoutable) {
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
        routable?.openHotBackupOnboarding()
    }
}

// MARK: - FloatingSheetContentViewModel

extension HotFinishActivationNeededViewModel: FloatingSheetContentViewModel {}
