//
//  AddressBookContactAddressRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct AddressBookContactAddressRowViewModel: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let addressIconViewModel: AddressIconViewModel
    let onDelete: () -> Void

    init(id: String, address: String, onDelete: @escaping () -> Void) {
        self.id = id
        title = address
        // Each entry holds a single network for now; the row reflects exactly one network.
        subtitle = Localization.commonNetworksCount(1)
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
            }
            .end {
                Button(action: viewModel.onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(DesignSystem.Tokens.Theme.Text.Accent.red)
                }
                .buttonStyle(.plain)
            }
    }
}
