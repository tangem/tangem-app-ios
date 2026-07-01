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
        rootContent
            .navigationTitle(Text(Localization.addressBookTitle))
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
    private var rootContent: some View {
        switch viewModel.contentState {
        case .empty:
            AddressBooksEmptyView(onAddContactTap: viewModel.openAddContact)
                .infinityFrame()

        default:
            searchableContent
        }
    }

    private var searchableContent: some View {
        nonEmptyContent
            .tangemSearchable(text: $viewModel.searchText, prompt: Localization.commonSearch)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }

    @ViewBuilder
    private var nonEmptyContent: some View {
        switch viewModel.contentState {
        case .failure:
            TangemUnableToLoadDataView(isButtonBusy: false, retryButtonAction: viewModel.retry)
                .infinityFrame()

        case .noResults:
            AddressBooksSearchNoResultsView()
                .infinityFrame()

        case .loading, .searching, .results:
            listContent

        case .empty:
            EmptyView()
        }
    }

    @ViewBuilder
    private var listContent: some View {
        GroupedScrollView(contentType: .lazy(spacing: 8)) {
            chipsView

            switch viewModel.contentState {
            case .loading, .searching:
                AddressBooksLoadingView()

            case .results(let contactsViewModels):
                GroupedSection(contactsViewModels, isLazy: true) {
                    AddressBookContactView(viewModel: $0)
                }
                .separatorStyle(.none)
                .cornerRadius(24)
                .horizontalPadding(0)

            default:
                EmptyView()
            }
        }
        .interContentPadding(12)
    }

    @ViewBuilder
    private var chipsView: some View {
        if viewModel.walletChips.count > 1 {
            HorizontalChipsView(
                chips: viewModel.walletChips,
                selectedId: $viewModel.selectedChipId,
                horizontalInset: 8,
                verticalInset: 8,
                chipHorizontalPadding: 12
            )
        }
    }
}
