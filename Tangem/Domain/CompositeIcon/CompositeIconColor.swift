//
//  CompositeIconColor.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Shared color palette for composite icons (account avatars, address-book contacts, etc.).
/// The string ids are a cross-platform contract synced with Android:
/// https://github.com/tangem-developments/tangem-app-android/blob/develop/common/ui/src/main/java/com/tangem/common/ui/account/CryptoPortfolioIconExt.kt
/// https://github.com/tangem-developments/tangem-app-android/blob/develop/domain/models/src/main/kotlin/com/tangem/domain/models/account/CryptoPortfolioIcon.kt
enum CompositeIconColor: String, CaseIterable, Hashable {
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

    static func randomElement() -> Self {
        allCases.randomElement() ?? .azure
    }
}
