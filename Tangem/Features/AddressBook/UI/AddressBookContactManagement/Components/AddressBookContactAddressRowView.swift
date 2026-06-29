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
    let onTap: () -> Void

    init(id: String, address: String, networksCount: Int, onTap: @escaping () -> Void) {
        self.id = id
        title = address
        subtitle = Localization.commonNetworksCount(networksCount)
        addressIconViewModel = AddressIconViewModel(address: address)
        self.onTap = onTap
    }
}

struct AddressBookContactAddressRowView: View {
    let viewModel: AddressBookContactAddressRowViewModel

    var body: some View {
        TangemRow(title: viewModel.title, subtitle: viewModel.subtitle)
            .verticalAlignment(.center)
            .start {
                AddressIconView(viewModel: viewModel.addressIconViewModel)
            }
            .onTap(viewModel.onTap)
    }
}
