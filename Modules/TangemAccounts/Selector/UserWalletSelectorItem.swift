//
//  UserWalletSelectorItem.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import TangemFoundation

public struct UserWalletSelectorItem: Identifiable {
    public let id: UserWalletId
    public let name: String
    public let image: UIImage?
    public let balance: SelectorBalance
    public let availability: SelectorAvailability

    public init(id: UserWalletId, name: String, image: UIImage?, balance: SelectorBalance, availability: SelectorAvailability) {
        self.id = id
        self.name = name
        self.image = image
        self.balance = balance
        self.availability = availability
    }
}
