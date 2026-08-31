//
//  MobileBackupTypesRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletBackup

@MainActor
protocol MobileBackupTypesRoutable: AnyObject {
    func openMobileUpgrade(userWalletModel: UserWalletModel)
    func openMobileOnboarding(input: MobileOnboardingInput)

    func openMobileBackupICloudDetails(backup: MobileWalletBackup, userWalletModel: UserWalletModel, onDelete: @escaping () -> Void)

    func openMobileBackupICloudStorageUnavailable(input: MobileBackupStorageUnavailableInput, output: MobileBackupStorageUnavailableOutput)
    func openMobileBackupICloudNotFound(output: MobileBackupNotFoundOutput)
}
