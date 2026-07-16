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
        .start {
            DesignSystem.Icons.SignPlus.regular20.image
                .padding(.all, 8)
                .background(DesignSystem.Color.bgStatusInfoSubtle)
                .cornerRadiusContinuous(12)
        }
        .onTap(viewModel.action)
    }
}
