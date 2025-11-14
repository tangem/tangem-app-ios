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
    struct Icon: Hashable {
        let name: Name
        let color: Color
    }
}

/// https://github.com/tangem-developments/tangem-app-android/blob/develop/common/ui/src/main/java/com/tangem/common/ui/account/CryptoPortfolioIconExt.kt
extension AccountModel.Icon {
    enum Color: String, CaseIterable, Hashable {
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

    enum Name: String, CaseIterable, Hashable {
        case letter
        case star
        case user
        case family
        case wallet
        case money
        case home
        case safe
        case beach
        case airplaneMode
        case shirt
        case shoppingBasket
        case favorite = "favourite" // Ew, UK spelling, but Android uses it
        case bookmark
        case startUp
        case clock
        case package
        case gift

        /// Explicit sort order for icon display
        /// When adding a new case, you MUST add it here with a specific order number
        var sortOrder: Int {
            switch self {
            case .letter: 0
            case .star: 1
            case .user: 2
            case .family: 3
            case .wallet: 4
            case .money: 5
            case .home: 6
            case .safe: 7
            case .beach: 8
            case .airplaneMode: 9
            case .shirt: 10
            case .shoppingBasket: 11
            case .favorite: 12
            case .bookmark: 13
            case .startUp: 14
            case .clock: 15
            case .package: 16
            case .gift: 17
            }
        }
    }
}

// MARK: - Comparable

extension AccountModel.Icon.Name: Comparable {
    static func < (lhs: AccountModel.Icon.Name, rhs: AccountModel.Icon.Name) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Convenience extensions

extension AccountModel.Icon {
    init?(rawName: String, rawColor: String) {
        guard
            let color = Color(rawValue: rawColor),
            let name = Name(rawValue: rawName)
        else {
            return nil
        }

        self.init(name: name, color: color)
    }
}
