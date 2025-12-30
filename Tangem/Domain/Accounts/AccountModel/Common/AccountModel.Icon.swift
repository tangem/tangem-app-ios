//
//  AccountModel.Icon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension AccountModel {
    struct Icon: Hashable {
        let name: Name
        let color: Color
    }
}

/// https://github.com/tangem-developments/tangem-app-android/blob/develop/common/ui/src/main/java/com/tangem/common/ui/account/CryptoPortfolioIconExt.kt
/// https://github.com/tangem-developments/tangem-app-android/blob/develop/domain/models/src/main/kotlin/com/tangem/domain/models/account/CryptoPortfolioIcon.kt
extension AccountModel.Icon {
    enum Color: String, CaseIterable, Hashable {
        case azure = "Azure"
        case caribbeanBlue = "CaribbeanBlue"
        case dullLavender = "DullLavender"
        case candyGrapeFizz = "CandyGrapeFizz"
        case sweetDesire = "SweetDesire"
        case palatinateBlue = "PalatinateBlue"
        case fuchsiaNebula = "FuchsiaNebula"
        case mexicanPink = "MexicanPink"
        case pelati = "Pelati"
        case pattypan = "Pattypan"
        case ufoGreen = "UFOGreen"
        case vitalGreen = "VitalGreen"
    }

    enum Name: String, CaseIterable, Hashable {
        case letter = "Letter"
        case star = "Star"
        case user = "User"
        case family = "Family"
        case wallet = "Wallet"
        case money = "Money"
        case home = "Home"
        case safe = "Safe"
        case beach = "Beach"
        case airplaneMode = "AirplaneMode"
        case shirt = "Shirt"
        case shoppingBasket = "ShoppingBasket"
        case favorite = "Favourite" // Ew, UK spelling, but Android uses it
        case bookmark = "Bookmark"
        case startUp = "StartUp"
        case clock = "Clock"
        case package = "Package"
        case gift = "Gift"

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

// MARK: - Comparable protocol conformance

extension AccountModel.Icon.Name: Comparable {
    static func < (lhs: AccountModel.Icon.Name, rhs: AccountModel.Icon.Name) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension AccountModel.Icon: CustomStringConvertible {
    var description: String {
        objectDescription(
            .empty,
            userInfo: [
                "name": name.rawValue,
                "color": color.rawValue,
            ]
        )
    }
}
