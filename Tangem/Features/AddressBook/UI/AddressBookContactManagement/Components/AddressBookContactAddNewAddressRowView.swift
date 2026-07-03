//
//  AddressBookContactAddNewAddressRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct AddressBookContactAddNewAddressRowViewModel {
    let isEnabled: Bool
    let action: () -> Void
}

struct AddressBookContactAddNewAddressRowView: View {
    let viewModel: AddressBookContactAddNewAddressRowViewModel

    var body: some View {
        TangemRow(
            title: Localization.addressBookAddAddress,
            subtitle: Localization.addressBookAddAddressDescription
        )
        .verticalAlignment(.center)
        .overrideTextColors(.init(title: titleColor))
        .start {
            DesignSystem.Icons.SignPlus.regular20.image
                .renderingMode(.template)
                .foregroundStyle(iconColor)
                .padding(.all, 8)
                .background(iconBackgroundColor)
                .cornerRadiusContinuous(10)
        }
        .onTap(viewModel.action)
    }

    private var titleColor: Color {
        viewModel.isEnabled ? DesignSystem.Color.textBrand : DesignSystem.Color.textTertiary
    }

    private var iconColor: Color {
        viewModel.isEnabled ? DesignSystem.Color.iconBrand : DesignSystem.Color.iconSecondary
    }

    private var iconBackgroundColor: Color {
        viewModel.isEnabled ? DesignSystem.Color.bgStatusInfoSubtle : DesignSystem.Color.bgTertiary
    }
}
