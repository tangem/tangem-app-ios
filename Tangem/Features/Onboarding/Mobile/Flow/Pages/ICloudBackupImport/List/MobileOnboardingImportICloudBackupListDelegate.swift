//
//  MobileOnboardingImportICloudBackupListDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletBackup

@MainActor
protocol MobileOnboardingImportICloudBackupListDelegate: AnyObject {
    func onBackupSelect(_ backup: MobileWalletBackup)
    func onBackupListClose()
}
