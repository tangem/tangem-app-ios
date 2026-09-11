//
//  MobileOnboardingImportICloudBackupDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MobileOnboardingImportICloudBackupDelegate: AnyObject {
    func didImportBackup(userWalletModel: UserWalletModel)
    func onBackupClose()
}
