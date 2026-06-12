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

    init(address: AddressBookAddress) {
        id = address.address
        title = address.address
        subtitle = Localization.commonNetworksCount(address.networks.count)
        addressIconViewModel = AddressIconViewModel(address: address.address)
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
