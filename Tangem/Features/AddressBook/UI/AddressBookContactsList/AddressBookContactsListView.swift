//
//  AddressBookContactsListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct AddressBookContactsListView: View {
    @ObservedObject var viewModel: AddressBookContactsListViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(spacing: 8)) {
            if viewModel.walletChips.count > 1 {
                HorizontalChipsView(
                    chips: viewModel.walletChips,
                    selectedId: $viewModel.selectedChipId,
                    horizontalInset: 8
                )
            }

            ForEach(viewModel.contacts) { contact in
                Text(contact.name)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 8)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    AddressBookContactsListView(
        viewModel: AddressBookContactsListViewModel(coordinator: AddressBookCoordinator())
    )
}
#endif // DEBUG
