//
//  AddressBookContactManagementView.swift
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
import TangemAccounts

struct AddressBookContactManagementView: View {
    @ObservedObject var viewModel: AddressBookContactManagementViewModel

    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            scrollContent
                .scrollDismissesKeyboard(.interactively)
                .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
                .navigationTitle(Text(viewModel.title))
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom) {
                    bottomButton
                }
                .toolbar {
                    NavigationToolbarButton
                        .close(placement: .topBarTrailing, action: viewModel.userDidRequestDismiss)
                }
                .alert(item: $viewModel.errorAlert) { $0.alert }
        }
    }

    private var scrollContent: some View {
        GroupedScrollView(contentType: .lazy(spacing: 16)) {
            AccountFormHeaderView(
                accountName: $viewModel.contactName,
                title: Localization.addressBookContactName,
                maxCharacters: viewModel.maxNameLength,
                placeholderText: Localization.addressBookNewContact,
                accountIconViewData: viewModel.iconViewData,
                isFocused: $isNameFocused
            )

            AccountFormGridView(
                selectedItem: $viewModel.selectedColor,
                items: viewModel.colors,
                content: { colorItem, isSelected in
                    makeColorItem(color: colorItem.color, isSelected: isSelected)
                }
            )

            GroupedSection(viewModel.addressesSection) { rowType in
                switch rowType {
                case .address(let rowViewModel):
                    AddressBookContactAddressRowView(viewModel: rowViewModel)
                case .addNewAddress(let rowViewModel):
                    AddressBookContactAddNewAddressRowView(viewModel: rowViewModel)
                }
            }
            .horizontalPadding(0)
        }
    }

    private func makeColorItem(color: Color, isSelected: Bool) -> some View {
        Circle()
            .fill(color)
            .overlay(makeItemOverlayView(isSelected: isSelected, strokeColor: color))
    }

    private func makeItemOverlayView(isSelected: Bool, strokeColor: Color) -> some View {
        Circle()
            .strokeBorder(AccountFormGridViewConstants.backgroundColor, lineWidth: isSelected ? 4 : 0)
            .overlay(
                Circle()
                    .strokeBorder(strokeColor, lineWidth: isSelected ? 2 : 0)
            )
    }

    private var bottomButton: some View {
        TangemButton(
            content: .text(AttributedString(Localization.commonDone)),
            action: viewModel.userDidRequestDone
        )
        .setCornerStyle(.rounded)
        .setHorizontalLayout(.infinity)
        .setSize(.x12)
        .setStyleType(.primary)
        .padding(.horizontal, 16)
    }
}
