//
//  HotBackupNeededViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class HotBackupNeededViewModel {
    let title = Localization.hwBackupNeedTitle
    let description = Localization.hwBackupNeedDescription
    let actionTitle = Localization.hwBackupNeedAction

    private weak var routable: HotBackupNeedRoutable?

    init(routable: HotBackupNeedRoutable) {
        self.routable = routable
    }
}

// MARK: - Internal methods

extension HotBackupNeededViewModel {
    func onCloseTap() {
        routable?.dismissHotBackupNeeded()
    }

    func onBackupTap() {
        routable?.dismissHotBackupNeeded()
        routable?.openHotBackupOnboarding()
    }
}

// MARK: - FloatingSheetContentViewModel

extension HotBackupNeededViewModel: FloatingSheetContentViewModel {}
