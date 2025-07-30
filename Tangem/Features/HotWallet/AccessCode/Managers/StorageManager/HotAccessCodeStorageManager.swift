//
//  HotAccessCodeStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotAccessCodeStorageManager {
    func getWrongAccessCodeStore(userWalletModel: UserWalletModel) -> HotWrongAccessCodeStore
    func storeWrongAccessCode(userWalletModel: UserWalletModel, lockInterval: TimeInterval)
    func clearWrongAccessCode(userWalletModel: UserWalletModel)
}
