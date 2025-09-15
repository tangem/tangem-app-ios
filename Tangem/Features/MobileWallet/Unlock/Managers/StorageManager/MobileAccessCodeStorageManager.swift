//
//  MobileAccessCodeStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol MobileAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletId: UserWalletId) -> MobileWrongAccessCodeStore
    func storeWrongAccessCode(userWalletId: UserWalletId, lockInterval: TimeInterval)
    func removeWrongAccessCode(userWalletId: UserWalletId)
}
