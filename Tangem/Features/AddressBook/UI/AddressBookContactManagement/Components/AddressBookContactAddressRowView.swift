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
    var id: String { address.address }
    var title: String { address.address }
    var subtitle: String { Localization.commonNetworksCount(address.networks.count) }

    let addressIconViewModel: AddressIconViewModel

    private let address: AddressBookAddress

    init(address: AddressBookAddress) {
        self.address = address
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
