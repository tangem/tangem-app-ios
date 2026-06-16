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

    private var scrollContent: some View {
        GroupedScrollView(contentType: .lazy(spacing: 16)) {
            AccountFormHeaderView(
                accountName: $viewModel.contactName,
                title: Localization.addressBookContactName,
                maxCharacters: viewModel.maxNameLength,
                placeholderText: Localization.addressBookNewContact,
                backgroundColor: DesignSystem.Tokens.Theme.Bg.secondary,
                accountIconViewData: viewModel.iconViewData,
                isFocused: $isNameFocused
            )

            AccountFormGridView(
                selectedItem: $viewModel.selectedColor,
                items: viewModel.colors,
                backgroundColor: DesignSystem.Tokens.Theme.Bg.secondary,
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
            .backgroundColor(DesignSystem.Tokens.Theme.Bg.secondary)
            .horizontalPadding(0)

            GroupedSection(viewModel.selectedWallet) { wallet in
                TangemRow(title: Localization.wcCommonWallet)
                    .verticalAlignment(.center)
                    .end { makeWalletValue(wallet: wallet) }
                    .if(wallet.isEditable) { $0.onTap(viewModel.userDidRequestWalletChange) }

            } footer: {
                DefaultFooterView(Localization.addressBookSaveWalletToDescription)
                    .padding(.horizontal, DesignSystem.Tokens.Spacing.s200)
            }
            .backgroundColor(DesignSystem.Tokens.Theme.Bg.secondary)
            .horizontalPadding(0)

            if viewModel.canDeleteContact {
                TangemRow()
                    .verticalAlignment(.center)
                    .start {
                        Text("Delete")
                            .style(DesignSystem.Tokens.Font.Body.medium, color: DesignSystem.Tokens.Theme.Text.Accent.red)
                            .lineLimit(1)
                    }
                    .onTap(viewModel.userDidRequestDelete)
                    .defaultRoundedBackground(with: DesignSystem.Tokens.Theme.Bg.secondary, verticalPadding: 0, horizontalPadding: 0)
                    .confirmationDialog(viewModel: $viewModel.confirmationDialog)
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

    private func makeWalletValue(wallet: AddressBookContactManagementViewModel.WalletRowType) -> some View {
        HStack(spacing: 4) {
            Text(wallet.name)
                .style(DesignSystem.Tokens.Font.Body.medium, color: DesignSystem.Tokens.Theme.Text.secondary)
                .lineLimit(1)

            if wallet.isEditable {
                Assets.Glyphs.selectIcon.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Tokens.Theme.Icon.secondary)
                    .frame(width: 20, height: 20)
            }
        }
    }

    private var bottomButton: some View {
        TangemButton(
            content: doneButtonContent,
            action: viewModel.userDidRequestDone
        )
        .setCornerStyle(.rounded)
        .setHorizontalLayout(.infinity)
        .setSize(.x12)
        .setStyleType(.primary)
        .setButtonState(
            isLoading: viewModel.isProcessing,
            isDisabled: !viewModel.isMainButtonEnabled
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var doneButtonContent: TangemButton.Content {
        let title = AttributedString(Localization.commonDone)

        switch viewModel.mainButtonIcon {
        case .leading(let image):
            return .combined(text: title, icon: image, iconPosition: .left)
        case .trailing(let image):
            return .combined(text: title, icon: image, iconPosition: .right)
        case .none:
            return .text(title)
        }
    }
}
