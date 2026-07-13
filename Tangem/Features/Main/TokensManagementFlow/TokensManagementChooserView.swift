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

    // MARK: - Redesign-aware styling

    private var isRedesign: Bool {
        viewModel.isAddAndOrganizeRedesignEnabled
    }

    private var rowBackgroundColor: Color {
        isRedesign ? Color.Tangem.Surface.level3 : Colors.Background.action
    }

    private var rowCornerRadius: CGFloat {
        isRedesign ? Constants.redesignRowCornerRadius : Constants.rowCornerRadius
    }

    private var titleColor: Color {
        isRedesign ? .Tangem.Text.Neutral.primary : Colors.Text.primary1
    }

    private var subtitleColor: Color {
        isRedesign ? .Tangem.Text.Neutral.secondary : Colors.Text.tertiary
    }

    private var accentColor: Color {
        isRedesign ? Color.Tangem.Graphic.Status.accent : Colors.Icon.accent
    }

    // MARK: - View Body

    @ViewBuilder
    var body: some View {
        if isRedesign {
            VStack(spacing: 8) {
                addTokensRow
                    .background(rowBackground)

                organizeTokensRow
                    .background(rowBackground)
            }
            .padding(.horizontal, Constants.horizontalInset)
        } else {
            VStack(spacing: 0) {
                addTokensRow

                organizeTokensRow
            }
            .background(rowBackground)
            .padding(.horizontal, Constants.horizontalInset)
        }
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
        RoundedRectangle(cornerRadius: rowCornerRadius, style: .continuous)
            .fill(rowBackgroundColor)
    }

    @ViewBuilder
    private func styledText(_ string: String, token: TangemTypographyToken, legacyFont: Font, color: Color) -> some View {
        if isRedesign {
            Text(string).style(token, color: color)
        } else {
            Text(string).style(legacyFont, color: color)
        }
    }

    private func row(icon: ImageType, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                iconView(icon: icon)

                VStack(alignment: .leading, spacing: 4) {
                    styledText(title, token: DesignSystem.Font.bodyMediumToken, legacyFont: Fonts.Bold.subheadline, color: titleColor)
                        .multilineTextAlignment(.leading)

                    styledText(subtitle, token: DesignSystem.Font.captionMediumToken, legacyFont: Fonts.Regular.caption1, color: subtitleColor)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                if isRedesign {
                    chevronView
                }
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
            .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
    }
}

// MARK: - Constants

private extension TokensManagementChooserView {
    enum Constants {
        static let iconContainerSize: CGFloat = 36
        static let iconCornerRadius: CGFloat = 18
        static let iconSize: CGFloat = 24
        static let rowCornerRadius: CGFloat = 14
        static let redesignRowCornerRadius: CGFloat = 20
        static let horizontalInset: CGFloat = 16
    }
}
