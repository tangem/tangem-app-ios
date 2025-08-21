//
//  MobileBackupNeededViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class MobileBackupNeededViewModel {
    let title = Localization.hwBackupNeedTitle
    let description = Localization.hwBackupNeedDescription
    let actionTitle = Localization.hwBackupNeedAction

    private let userWalletModel: UserWalletModel
    private weak var routable: MobileBackupNeededRoutable?

    init(userWalletModel: UserWalletModel, routable: MobileBackupNeededRoutable) {
        self.userWalletModel = userWalletModel
        self.routable = routable
    }
}

// MARK: - Internal methods

extension MobileBackupNeededViewModel {
    func onCloseTap() {
        routable?.dismissMobileBackupNeeded()
    }

    func onBackupTap() {
        routable?.dismissMobileBackupNeeded()
        let input = MobileOnboardingInput(flow: .seedPhraseBackup(userWalletModel: userWalletModel))
        routable?.openMobileOnboarding(input: input)
    }
}

// MARK: - FloatingSheetContentViewModel

extension MobileBackupNeededViewModel: FloatingSheetContentViewModel {}
