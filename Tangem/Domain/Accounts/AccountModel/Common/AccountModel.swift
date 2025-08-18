//
//  AccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

enum AccountModel {
    case standard(CryptoAccounts)

    @available(*, unavailable, message: "This account type is not implemented yet")
    case smart(any SmartAccountModel)

    @available(*, unavailable, message: "This account type is not implemented yet")
    case visa(any VisaAccountModel)
}

// MARK: - Inner types

extension AccountModel {
    struct Icon {
        let name: Name
        let color: Color
    }
}

extension AccountModel.Icon {
    enum Color: String, CaseIterable {
        case brightBlue
        case coralRed
        case cyan
        case darkGreen
        case deepPurple
        case hotPink
        case lavender
        case magenta
        case mediumGreen
        case purple
        case royalBlue
        case yellow
    }

    enum Name: String, CaseIterable {
        case airplane
        case beach
        case bookmark
        case clock
        case family
        case favorite
        case gift
        case home
        case letter
        case money
        case package
        case safe
        case shirt
        case shoppingBasket
        case star
        case startUp
        case user
        case wallet
    }
}
