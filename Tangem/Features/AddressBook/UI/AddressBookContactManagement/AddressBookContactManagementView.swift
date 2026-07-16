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
            .background(DesignSystem.Color.bgBase.ignoresSafeArea())
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
                backgroundColor: DesignSystem.Color.bgSecondary,
                accountIconViewData: viewModel.iconViewData,
                isFocused: $isNameFocused
            )

            AccountFormGridView(
                selectedItem: $viewModel.selectedColor,
                items: viewModel.colors,
                backgroundColor: DesignSystem.Color.bgSecondary,
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
            .backgroundColor(DesignSystem.Color.bgSecondary)
            .horizontalPadding(0)

            GroupedSection(viewModel.selectedWallet) { wallet in
                TangemRow(title: Localization.wcCommonWallet)
                    .verticalAlignment(.center)
                    .end { makeWalletValue(wallet: wallet) }
                    .if(wallet.isEditable) { $0.onTap(viewModel.userDidRequestWalletChange) }

            } footer: {
                DefaultFooterView(Localization.addressBookSaveWalletToDescription)
                    .padding(.horizontal, 16)
            }
            .backgroundColor(DesignSystem.Color.bgSecondary)
            .horizontalPadding(0)

            if viewModel.canDeleteContact {
                TangemRow()
                    .verticalAlignment(.center)
                    .start {
                        Text(Localization.commonDelete)
                            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textAccentRed)
                            .lineLimit(1)
                    }
                    .onTap(viewModel.userDidRequestDelete)
                    .defaultRoundedBackground(with: DesignSystem.Color.bgSecondary, verticalPadding: 0, horizontalPadding: 0)
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
            .strokeBorder(DesignSystem.Color.bgSecondary, lineWidth: isSelected ? 4 : 0)
            .overlay(
                Circle()
                    .strokeBorder(strokeColor, lineWidth: isSelected ? 2 : 0)
            )
    }

    private func makeWalletValue(wallet: AddressBookContactManagementViewModel.WalletRowType) -> some View {
        HStack(spacing: 4) {
            Text(wallet.wallet)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            if wallet.isEditable {
                Assets.Glyphs.selectIcon.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
                    .frame(width: 20, height: 20)
            }
        }
    }

    private var bottomButton: some View {
        TangemButton(
            content: doneButtonContent,
            action: viewModel.userDidRequestDone
        )
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
