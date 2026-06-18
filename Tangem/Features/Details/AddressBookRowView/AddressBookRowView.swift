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
import TangemAccessibilityIdentifiers

struct AddressBookRowView: View {
    let viewModel: AddressBookRowViewModel

    var body: some View {
        TangemRow(
            title: Localization.addressBookTitle,
            subtitle: Localization.addressBookDescription
        )
        .verticalAlignment(.center)
        .start {
            DesignSystem.Icons.AddressPolygon.regular20.image
                .padding(.all, 8)
                .background(DesignSystem.Color.bgStatusInfoSubtle)
                .cornerRadiusContinuous(12)
        }
        .end(icon: DesignSystem.Icons.ChevronRight.regular20)
        .onTap(viewModel.action)
        .accessibilityIdentifier(DetailsAccessibilityIdentifiers.addressBookButton)
    }
}
