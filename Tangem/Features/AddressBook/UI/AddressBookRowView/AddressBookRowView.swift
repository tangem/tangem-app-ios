//
//  AddressBookRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct AddressBookRowView: View {
    let viewModel: AddressBookRowViewModel

    var body: some View {
        Button(action: viewModel.action) {
            TangemRow(
                title: Localization.addressBookTitle,
                subtitle: Localization.addressBookDescription
            )
            .verticalAlignment(.center)
            .start {
                DesignSystem.Icons.Error.regular20.image
                    .padding(.all, DesignSystem.Tokens.Spacing.s100)
                    .background(DesignSystem.Tokens.Theme.Bg.Status.infoSubtle)
                    .cornerRadiusContinuous(DesignSystem.Tokens.CornerRadius._150)
            }
            .end(icon: DesignSystem.Icons.ChevronRight.regular20)
        }
    }
}
