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
            }
            .scrollDismissesKeyboard(.automatic)
            .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
            .navigationTitle(Text("Contact"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                NavigationToolbarButton.close(placement: .topBarTrailing, action: viewModel.dismiss)
            }
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
}
