//
//  SendDestinationAddressBookView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SendDestinationAddressBookView: View {
    let viewModel: SendDestinationAddressBookViewModel

    var body: some View {
        GroupedSection(viewModel.displayedContacts) { contact in
            AddressBookContactView(viewModel: contact)
        } header: {
            DefaultHeaderView(Localization.addressBookTitle)
                .infinityFrame(axis: .horizontal, alignment: .leading)
                .overlay(alignment: .trailing) {
                    Button(action: viewModel.viewAllAction) {
                        Text(Localization.commonViewAll)
                            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textBrand)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
        }
        .horizontalPadding(0)
        .backgroundColor(Colors.Background.action)
        .interItemSpacing(0)
        .separatorStyle(.none)
    }
}
