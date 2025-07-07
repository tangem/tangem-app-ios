//
//  HotAccessCodeStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol HotAccessCodeStorageManager: AnyObject {
    typealias UserWalletId = String
    func getWrongAccessCodeStore(userWalletId: UserWalletId) -> HotWrongAccessCodeStore
    func storeWrongAccessCode(userWalletId: UserWalletId, date: Date)
    func clearWrongAccessCode(userWalletId: UserWalletId)
    func clearWrongAccessCode()
}
