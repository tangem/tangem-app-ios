//
//  AddressBooksView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct AddressBooksView: View {
    @ObservedObject var viewModel: AddressBooksViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(spacing: 8)) {
            if viewModel.walletChips.count > 1 {
                HorizontalChipsView(
                    chips: viewModel.walletChips,
                    selectedId: $viewModel.selectedChipId,
                    horizontalInset: 8,
                    verticalInset: 8
                )
            }

            content
        }
        .navigationTitle(Text(Localization.addressBookTitle))
        // [REDACTED_TODO_COMMENT]
        .background(DesignSystem.Tokens.Theme.Bg.base.edgesIgnoringSafeArea(.all))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: viewModel.openAddContact) {
                    DesignSystem.Icons.SignPlus.regular20.image
                        .renderingMode(.template)
                        .foregroundColor(DesignSystem.Tokens.Theme.Icon.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.contactsViewModels {
        case .loading:
            // [REDACTED_TODO_COMMENT]
            EmptyView()

        case .success(let contactsViewModels) where contactsViewModels.isEmpty:
            // [REDACTED_TODO_COMMENT]
            EmptyView()

        case .success(let contactsViewModels):
            GroupedSection(contactsViewModels, isLazy: true) {
                AddressBookContactView(viewModel: $0)
            }
            .horizontalPadding(0)
        }
    }
}
