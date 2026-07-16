//
//  AddTokenConfirmView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts
import TangemAccessibilityIdentifiers
import TangemLocalization

struct AddTokenConfirmView: View {
    @ObservedObject var viewModel: AddTokenConfirmViewModel

    var body: some View {
        VStack(spacing: 0) {
            tokenHeader
                .padding(.bottom, AddTokenRedesignedConstants.tokenHeaderBottomSpacing)

            accountSelectorRow
                .background(Color.Tangem.Surface.level3)
                .cornerRadiusContinuous(AddTokenRedesignedConstants.cornerRadius)
                .padding(.bottom, AddTokenRedesignedConstants.itemSpacing)

            networkSelectorRow
                .background(Color.Tangem.Surface.level3)
                .cornerRadiusContinuous(AddTokenRedesignedConstants.cornerRadius)
                .padding(.bottom, AddTokenRedesignedConstants.sectionSpacing)

            confirmButton
        }
        .padding(.horizontal, AddTokenRedesignedConstants.horizontalPadding)
        .padding(.bottom, AddTokenRedesignedConstants.verticalPadding)
        .animation(.default, value: viewModel.isSaving)
        .task { await viewModel.loadWalletImage() }
    }

    // MARK: - Token Header

    private var tokenHeader: some View {
        VStack(spacing: 0) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: .init(bothDimensions: AddTokenRedesignedConstants.tokenIconSize),
                isWithOverlays: false
            )
            .padding(.bottom, AddTokenRedesignedConstants.tokenIconToTitleSpacing)

            Text(viewModel.tokenName)
                .style(Fonts.Bold.title2, color: Colors.Text.primary1)

            Text(viewModel.tokenSubtitle)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AddTokenRedesignedConstants.tokenHeaderTopPadding)
    }

    @ViewBuilder
    private var walletIcon: some View {
        if let imageValue = viewModel.walletIcon {
            imageValue.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: AddTokenRedesignedConstants.selectorRowIconSize,
                    height: AddTokenRedesignedConstants.selectorRowIconSize
                )
        } else {
            Color.clear
                .frame(
                    width: AddTokenRedesignedConstants.selectorRowIconSize,
                    height: AddTokenRedesignedConstants.selectorRowIconSize
                )
        }
    }

    private var accountSelectorRow: some View {
        SelectorRow(
            label: viewModel.accountRowData.label,
            value: viewModel.accountRowData.name,
            isInteractive: viewModel.isAccountSelectionAvailable,
            onTap: viewModel.handleAccountTap
        ) {
            switch viewModel.accountRowData.kind {
            case .account(let iconData):
                AccountIconView(data: iconData, settings: .mediumSized)
            case .wallet:
                walletIcon
            }
        }
    }

    private var networkSelectorRow: some View {
        SelectorRow(
            label: Localization.wcCommonNetwork,
            value: viewModel.networkRowData.name,
            isInteractive: viewModel.isNetworkSelectionAvailable,
            onTap: viewModel.handleNetworkTap
        ) {
            NetworkIcon(
                imageAsset: viewModel.networkRowData.iconImageAsset,
                isActive: true,
                isMainIndicatorVisible: false,
                showBackground: false,
                size: .init(bothDimensions: AddTokenRedesignedConstants.selectorRowIconSize)
            )
        }
    }

    // MARK: - Selector Row

    private struct SelectorRow<Icon: View>: View {
        let label: String
        let value: String
        let isInteractive: Bool
        let onTap: () -> Void
        @ViewBuilder let icon: () -> Icon

        var body: some View {
            Button(action: onTap) {
                HStack(spacing: AddTokenRedesignedConstants.selectorRowContentSpacing) {
                    icon()

                    VStack(alignment: .leading, spacing: AddTokenRedesignedConstants.selectorRowLabelValueSpacing) {
                        Text(label)
                            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                        Text(value)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                    }

                    Spacer(minLength: 0)

                    if isInteractive {
                        Assets.Glyphs.selectIcon.image
                            .resizable()
                            .renderingMode(.template)
                            .frame(
                                width: AddTokenRedesignedConstants.chevronIconSize,
                                height: AddTokenRedesignedConstants.chevronIconSize
                            )
                            .foregroundStyle(Colors.Icon.informative)
                    }
                }
                .padding(.vertical, AddTokenRedesignedConstants.selectorRowVerticalPadding)
                .padding(.horizontal, AddTokenRedesignedConstants.selectorRowHorizontalPadding)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(!isInteractive)
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        TangemButton(
            content: viewModel.confirmButtonContent,
            action: viewModel.handleConfirmTap
        )
        .setStyleType(.primary)
        .setHorizontalLayout(.infinity)
        .setSize(.x12)
        .setButtonState(isLoading: viewModel.isSaving, isDisabled: viewModel.isTokenAlreadyAdded)
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.addTokenButton)
    }
}
