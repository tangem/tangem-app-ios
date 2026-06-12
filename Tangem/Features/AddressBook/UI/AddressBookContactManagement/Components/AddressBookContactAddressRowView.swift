//
//  AddressBookContactAddressRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemLocalization

struct AddressBookContactAddressRowViewModel: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let addressIconViewModel: AddressIconViewModel

    init(entry: VerifiedAddressEntry) {
        id = entry.id.stringValue
        title = entry.address
        // Each entry holds a single network in Foundation-2; the row reflects exactly one network.
        subtitle = Localization.commonNetworksCount(1)
        addressIconViewModel = AddressIconViewModel(address: entry.address)
    }
}

struct AddressBookContactAddressRowView: View {
    let viewModel: AddressBookContactAddressRowViewModel

    var body: some View {
        TangemRow(title: viewModel.title, subtitle: viewModel.subtitle)
            .verticalAlignment(.center)
            .start {
                AddressIconView(viewModel: viewModel.addressIconViewModel)
                    .frame(size: CGSize(bothDimensions: 36))
            }
    }
}
