//
//  AddressBookContactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct AddressBookContactView: View {
    let contact: AddressBookContact

    var title: String { contact.name }
    var subtitle: String { Localization.addressBookAddresses(contact.addresses.count) }

    var body: some View {
        TangemRow(title: title, subtitle: subtitle)
            .verticalAlignment(.center)
            .start { AddressBookContactNameIconView(name: contact.name) }
    }
}

struct AddressBookContactNameIconView: View {
    let name: String

    var initials: String {
        name.first?.uppercased() ?? ""
    }

    var body: some View {
        Color.blue
            .frame(width: 40, height: 40)
            .overlay {
                Text(initials)
                    .style(DesignSystem.Tokens.Font.Body.medium, color: DesignSystem.Tokens.Theme.Text.StaticDark.primary)
            }
            .clipShape(Circle())
    }
}
