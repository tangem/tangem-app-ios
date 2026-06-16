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
    let onDelete: () -> Void

    init(id: String, address: String, networksCount: Int, onDelete: @escaping () -> Void) {
        self.id = id
        title = address
        subtitle = Localization.commonNetworksCount(networksCount)
        addressIconViewModel = AddressIconViewModel(address: address)
        self.onDelete = onDelete
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
            .end {
                Button(action: viewModel.onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.plain)
            }
    }
}
