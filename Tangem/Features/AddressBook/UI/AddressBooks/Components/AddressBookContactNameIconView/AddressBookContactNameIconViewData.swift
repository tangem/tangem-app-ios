//
//  AddressBookContactNameIconViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddressBookContactNameIconViewData: Equatable {
    let letter: String
    let color: Color
}

extension AddressBookContactNameIconViewData {
    init(contact: AddressBookContact) {
        self.init(
            letter: contact.name.firstLetter,
            color: CompositeIconColorPalette.color(for: contact.appearance.color)
        )
    }
}
