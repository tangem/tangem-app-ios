//
//  MobileRemoveWalletNotificationRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

@MainActor
protocol MobileRemoveWalletNotificationRoutable: AnyObject {
    func openMobileRemoveWallet(removeManager: MobileRemoveWalletManager)
    func openMobileOnboardingFromRemoveWalletNotification(input: MobileOnboardingInput)
    func openMobileBackupTypesFromRemoveWalletNotification(userWalletModel: UserWalletModel)
    func dismissMobileRemoveWalletNotification()
}
