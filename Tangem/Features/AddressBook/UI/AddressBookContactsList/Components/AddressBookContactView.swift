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
    let viewModel: AddressBookContactViewModel

    var body: some View {
        TangemRow(title: viewModel.title, subtitle: viewModel.subtitle)
            .verticalAlignment(.center)
            .start { AddressBookContactNameIconView(letter: viewModel.letter) }
            .onTap(viewModel.action)
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
