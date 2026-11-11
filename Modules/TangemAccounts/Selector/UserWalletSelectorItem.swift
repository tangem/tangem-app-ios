//
//  UserWalletSelectorItem.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import TangemFoundation
import TangemUI

public struct UserWalletSelectorItem: Identifiable {
    public let id: UserWalletId
    public let name: String
    public let icon: WalletIconContent?
    public let balance: SelectorBalance
    public let availability: SelectorAvailability

    public init(id: UserWalletId, name: String, icon: WalletIconContent?, balance: SelectorBalance, availability: SelectorAvailability) {
        self.id = id
        self.name = name
        self.icon = icon
        self.balance = balance
        self.availability = availability
    }
}
