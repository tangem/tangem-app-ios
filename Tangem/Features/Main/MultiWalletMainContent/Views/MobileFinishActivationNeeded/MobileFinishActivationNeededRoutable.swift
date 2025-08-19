//
//  MobileFinishActivationNeededRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol MobileFinishActivationNeededRoutable: AnyObject {
    func dismissMobileFinishActivationNeeded()
    func openMobileBackupOnboarding(userWalletModel: UserWalletModel)
}
