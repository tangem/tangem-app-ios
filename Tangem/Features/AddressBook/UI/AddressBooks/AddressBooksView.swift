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
            content
        }
        .interContentPadding(12)
        .navigationTitle(Text(Localization.addressBookTitle))
        // [REDACTED_TODO_COMMENT]
        .background(DesignSystem.Color.bgBase.edgesIgnoringSafeArea(.all))
        .toolbar { trailingToolbarItem }
    }

    @ToolbarContentBuilder
    private var trailingToolbarItem: some ToolbarContent {
        if viewModel.showsToolbarAddButton {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: viewModel.openAddContact) {
                    DesignSystem.Icons.SignPlus.regular20.image
                        .renderingMode(.template)
                        .foregroundColor(DesignSystem.Color.iconPrimary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.contactsViewModels {
        case .loading:
            AddressBooksLoadingView()

        case .success(let contactsViewModels) where contactsViewModels.isEmpty:
            AddressBooksEmptyView(onAddContactTap: viewModel.openAddContact)

        case .success(let contactsViewModels):
            chipsView

            GroupedSection(contactsViewModels, isLazy: true) {
                AddressBookContactView(viewModel: $0)
            }
            .separatorStyle(.none)
            .cornerRadius(24)
            .horizontalPadding(0)
        }
    }

    @ViewBuilder
    private var chipsView: some View {
        if viewModel.walletChips.count > 1 {
            HorizontalChipsView(
                chips: viewModel.walletChips,
                selectedId: $viewModel.selectedChipId,
                horizontalInset: 8,
                verticalInset: 8
            )
        }
    }
}
