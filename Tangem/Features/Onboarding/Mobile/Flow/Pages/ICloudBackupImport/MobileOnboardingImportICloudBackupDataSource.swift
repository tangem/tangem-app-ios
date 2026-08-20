//
//  MobileOnboardingImportICloudBackupDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletBackup

protocol MobileOnboardingImportICloudBackupDataSource: AnyObject {
    func getBackup() -> MobileWalletBackup?
}
