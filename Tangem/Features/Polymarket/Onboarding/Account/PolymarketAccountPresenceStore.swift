//
//  PolymarketAccountPresenceStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol PolymarketAccountPresenceStore {
    func hasAccount(userWalletId: UserWalletId) -> Bool
    func setHasAccount(_ value: Bool, for userWalletId: UserWalletId)
}

// MARK: - AppSettings

extension AppSettings: PolymarketAccountPresenceStore {
    func hasAccount(userWalletId: UserWalletId) -> Bool {
        polymarketHasAccount[userWalletId.stringValue, default: false]
    }

    func setHasAccount(_ value: Bool, for userWalletId: UserWalletId) {
        polymarketHasAccount[userWalletId.stringValue] = value
    }
}
