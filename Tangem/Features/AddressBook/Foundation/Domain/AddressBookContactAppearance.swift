//
//  AddressBookContactAppearance.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

typealias AddressBookContactColor = AccountModel.CompositeIcon.Color

struct AddressBookContactAppearance: Hashable {
    let color: AddressBookContactColor
}

// MARK: - Blob color id

extension AddressBookContactAppearance {
    /// The cross-platform blob stores the avatar background as a bare color id (e.g. "MexicanPink").
    var rawColor: String { color.rawValue }

    /// Maps a stored color id back to the appearance, falling back to a fresh icon color for unknown ids.
    init(rawColor: String) {
        color = AddressBookContactColor(rawValue: rawColor) ?? AccountModelUtils.UI.newAccountIcon().color
    }
}
