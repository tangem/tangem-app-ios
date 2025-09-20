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
    struct Icon: Equatable {
        let name: Name
        let color: Color
    }
}

/// https://github.com/tangem-developments/tangem-app-android/blob/develop/common/ui/src/main/java/com/tangem/common/ui/account/CryptoPortfolioIconExt.kt
extension AccountModel.Icon {
    enum Color: String, CaseIterable {
        case azure
        case caribbeanBlue
        case dullLavender
        case candyGrapeFizz
        case sweetDesire
        case palatinateBlue
        case fuchsiaNebula
        case mexicanPink
        case pelati
        case pattypan
        case ufoGreen
        case vitalGreen
    }

    enum Name: String, CaseIterable {
        case airplaneMode
        case beach
        case bookmark
        case clock
        case family
        case favorite = "favourite" // Ew, UK spelling, but Android uses it
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

// MARK: - Convenience extensions

extension AccountModel.Icon {
    init?(rawName: String, rawColor: String) {
        guard
            let name = Name(rawValue: rawName),
            let color = Color(rawValue: rawColor)
        else {
            return nil
        }

        self.init(name: name, color: color)
    }
}
