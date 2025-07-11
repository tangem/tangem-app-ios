//
//  HotBackupTypesRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotBackupTypesRoutable: AnyObject {
    func openHotBackupOnboardingSeedPhrase()
    func openHotBackupRevealSeedPhrase(userWalletModel: UserWalletModel)
}
