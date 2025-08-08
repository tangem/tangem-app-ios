//
//  HotBackupTypesRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotBackupTypesRoutable: AnyObject {
    func openHotBackupOnboardingSeedPhrase(userWalletModel: UserWalletModel)
    func openHotBackupRevealSeedPhrase(userWalletModel: UserWalletModel)
}
