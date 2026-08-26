//
//  MobileFinishActivationNeededRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletSdk

@MainActor
protocol MobileFinishActivationNeededRoutable: AnyObject {
    func dismissMobileFinishActivationNeeded()
    func openMobileBackup(userWalletModel: UserWalletModel)
    func openMobileBackupOnboarding(userWalletModel: UserWalletModel, context: MobileWalletContext)
}
