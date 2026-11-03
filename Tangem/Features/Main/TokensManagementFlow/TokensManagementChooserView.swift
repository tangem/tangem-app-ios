//
//  TokensManagementChooserView.swift
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
import TangemAccessibilityIdentifiers

struct TokensManagementChooserView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: TokensManagementFlowCoordinator

    // MARK: - Styling

    private var rowBackgroundColor: Color {
        DesignSystem.Color.bgSecondary
    }

    private var titleColor: Color {
        DesignSystem.Color.textPrimary
    }

    private var subtitleColor: Color {
        DesignSystem.Color.textSecondary
    }

    private var accentColor: Color {
        DesignSystem.Color.iconAccentBlue
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 8) {
            addTokensRow
                .background(rowBackground)

            organizeTokensRow
                .background(rowBackground)
        }
        .padding(.horizontal, Constants.horizontalInset)
    }

    // MARK: - Sub Views

    private var addTokensRow: some View {
        row(
            icon: Assets.plus24,
            title: Localization.addAndManageSheetManageTitle,
            subtitle: Localization.addAndManageSheetManageSubtitle,
            action: viewModel.openAddTokens
        )
        .accessibilityIdentifier(TokensManagementChooserAccessibilityIdentifiers.addTokensRow)
    }

    private var organizeTokensRow: some View {
        row(
            icon: Assets.OrganizeTokens.filterIcon,
            title: Localization.organizeTokensTitle,
            subtitle: Localization.addAndManageSheetOrganizeSubtitle,
            action: viewModel.openOrganize
        )
        .accessibilityIdentifier(TokensManagementChooserAccessibilityIdentifiers.organizeTokensRow)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: Constants.rowCornerRadius, style: .continuous)
            .fill(rowBackgroundColor)
    }

    private func row(icon: ImageType, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                iconView(icon: icon)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .style(DesignSystem.Font.bodyMediumToken, color: titleColor)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .style(DesignSystem.Font.captionMediumToken, color: subtitleColor)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                chevronView
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func iconView(icon: ImageType) -> some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: Constants.iconCornerRadius)
                .fill(accentColor.opacity(0.1))
                .frame(width: Constants.iconContainerSize, height: Constants.iconContainerSize)

            icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundStyle(accentColor)
        }
    }

    private var chevronView: some View {
        DesignSystem.Icons.ChevronRight.regular20.image
            .renderingMode(.template)
            .bold()
            .foregroundStyle(DesignSystem.Color.iconSecondary)
    }
}

// MARK: - Constants

private extension TokensManagementChooserView {
    enum Constants {
        static let iconContainerSize: CGFloat = 36
        static let iconCornerRadius: CGFloat = 18
        static let iconSize: CGFloat = 24
        static let rowCornerRadius: CGFloat = 24
        static let horizontalInset: CGFloat = 16
    }
}
