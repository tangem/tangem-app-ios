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

struct AddressBookContactViewModel: Identifiable {
    var id: String { title }

    let title: String
    let subtitle: String
    let letter: String

    let action: () -> Void

    init(contact: AddressBookContact, action: @escaping () -> Void) {
        title = contact.name
        subtitle = Localization.addressBookAddresses(contact.addresses.count)
        letter = contact.firstLetter

        self.action = action
    }
}

struct AddressBookContactView: View {
    let viewModel: AddressBookContactViewModel

    var body: some View {
        Button(action: viewModel.action) {
            TangemRow(title: viewModel.title, subtitle: viewModel.subtitle)
                .verticalAlignment(.center)
                .start { AddressBookContactNameIconView(letter: viewModel.letter) }
                .contentShape(Rectangle())
        }
    }
}

struct AddressBookContactNameIconView: View {
    let letter: String

    var body: some View {
        Color.blue
            .frame(width: 40, height: 40)
            .overlay {
                Text(letter.uppercased())
                    .style(DesignSystem.Tokens.Font.Body.medium, color: DesignSystem.Tokens.Theme.Text.StaticDark.primary)
            }
            .clipShape(Circle())
    }
}
