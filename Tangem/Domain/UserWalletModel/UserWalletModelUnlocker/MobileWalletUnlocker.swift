//
//  MobileWalletUnlocker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import TangemFoundation

class MobileWalletUnlocker: UserWalletModelUnlocker {
    var canUnlockAutomatically: Bool { !info.isAccessCodeSet }
    var canShowUnlockUIAutomatically: Bool { false }

    private let userWalletId: UserWalletId
    private let info: HotWalletInfo

    init(userWalletId: UserWalletId, info: HotWalletInfo) {
        self.userWalletId = userWalletId
        self.info = info
    }

    func unlock() async -> UserWalletModelUnlockerResult {
        fatalError("MobileWalletUnlocker is not implemented")
    }
}
