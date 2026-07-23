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

    @State private var headerHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            scrollContent
                .scrollDismissesKeyboard(.immediately)

            header
        }
        .infinityFrame(axis: .vertical, alignment: .top)
        .background(DesignSystem.Color.bgBase.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { bottomButton }
        .navigationBarHidden(true)
        .alert(item: $viewModel.alert) { $0.alert }
        .onFirstAppear {
            viewModel.onFirstAppear()
            if viewModel.focusesNameOnFirstAppear {
                isNameFocused = true
            }
        }
    }

    private var header: some View {
        NavigationHeader(
            leadingContent: { EmptyView() },
            principalContent: {
                Text(viewModel.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            },
            trailingContent: {
                NavigationBarButton.close(action: viewModel.userDidRequestDismiss).redesigned()
            }
        )
        .readGeometry(\.size.height, bindTo: $headerHeight)
    }

    private var scrollContent: some View {
        GroupedScrollView(contentType: .lazy(spacing: 16)) {
            Color.clear
                .frame(height: headerHeight)

            FormHeaderView(
                accountName: $viewModel.contactName,
                title: Localization.addressBookContactName,
                maxCharacters: viewModel.maxNameLength,
                placeholderText: Localization.addressBookNewContact,
                backgroundColor: DesignSystem.Color.bgSecondary,
                accountIconViewData: viewModel.iconViewData,
                errorMessage: viewModel.nameError,
                isFocused: $isNameFocused
            )
            .style(.addressBook)

            AccountFormGridView(
                selectedItem: $viewModel.selectedColor,
                items: viewModel.colors,
                backgroundColor: DesignSystem.Color.bgSecondary,
                horizontalPadding: 16,
                cornerRadius: 24,
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
            .separatorStyle(.none)
            .cornerRadius(24)
            .horizontalPadding(0)

            GroupedSection(viewModel.selectedWallet) { wallet in
                TangemRow(title: Localization.addressBookSaveToWalletTitle)
                    .end { makeWalletValue(wallet: wallet) }
                    .if(wallet.isEditable) { $0.onTap(viewModel.userDidRequestWalletChange) }

            } footer: {
                Text(Localization.addressBookSaveWalletToDescription)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }
            .backgroundColor(DesignSystem.Color.bgSecondary)
            .cornerRadius(20)
            .horizontalPadding(0)

            if viewModel.canDeleteContact {
                TangemRow()
                    .start {
                        Text(Localization.addressBookDeleteContact)
                            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textAccentRed)
                            .lineLimit(1)
                    }
                    .onTap(viewModel.userDidRequestDelete)
                    .defaultRoundedBackground(with: DesignSystem.Color.bgSecondary, verticalPadding: 0, horizontalPadding: 0, cornerRadius: 24)
                    .confirmationDialog(viewModel: $viewModel.confirmationDialog)
            }
        }
        .padding(.top, 12)
    }

    private func makeColorItem(color: Color, isSelected: Bool) -> some View {
        Circle()
            .fill(color)
            .overlay(makeItemOverlayView(isSelected: isSelected, strokeColor: color))
            .frame(width: 40, height: 40)
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
            Text(wallet.name)
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
        let title = AttributedString(viewModel.mainButtonTitle)

        guard viewModel.isMainButtonEnabled else {
            return .text(title)
        }

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
