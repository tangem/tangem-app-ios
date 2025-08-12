//
//  HotFinishActivationNeededRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotFinishActivationNeededRoutable: AnyObject {
    func dismissHotFinishActivationNeeded()
    func openHotBackupOnboarding(userWalletModel: UserWalletModel)
}
