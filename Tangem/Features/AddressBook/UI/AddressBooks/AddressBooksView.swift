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
        content
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
        if case .success(let contactsViewModels) = viewModel.contactsViewModels, contactsViewModels.isEmpty {
            AddressBooksEmptyView(onAddContactTap: viewModel.openAddContact)
                .infinityFrame()
        } else {
            GroupedScrollView(contentType: .lazy(spacing: 8)) {
                scrollContent
            }
            .interContentPadding(12)
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        chipsView

        switch viewModel.contactsViewModels {
        case .loading:
            AddressBooksLoadingView()

        case .failure:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.retry)

        case .success(let contactsViewModels):
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
