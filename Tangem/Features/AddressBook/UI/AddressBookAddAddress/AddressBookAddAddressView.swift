//
//  AddressBookAddAddressView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct AddressBookAddAddressView: View {
    @ObservedObject var viewModel: AddressBookAddAddressViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 24)) {
            GroupedSection(viewModel.destinationAddressViewModel) {
                SendDestinationAddressView(viewModel: $0)
            }
            .interItemSpacing(12)
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)

            GroupedSection(viewModel.additionalFieldViewModel) {
                SendDestinationAdditionalFieldView(viewModel: $0)
            } footer: {
                DefaultFooterView(Localization.sendRecipientMemoFooter)
            }
            .innerContentPadding(12)
            .backgroundColor(Colors.Background.action)
        }
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .navigationTitle(Text(Localization.addressBookAddAddress))
        .navigationBarTitleDisplayMode(.inline)
    }
}
