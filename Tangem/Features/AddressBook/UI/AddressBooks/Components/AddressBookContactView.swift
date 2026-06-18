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
            .start { AddressBookContactNameIconView(letter: viewModel.letter, color: viewModel.iconColor) }
            .onTap(viewModel.action)
    }
}

struct AddressBookContactNameIconView: View {
    let letter: String
    let color: Color

    var body: some View {
        color
            .frame(width: 40, height: 40)
            .overlay {
                Text(letter)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textStaticDarkPrimary)
            }
            .clipShape(Circle())
    }
}
