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
import TangemAccessibilityIdentifiers

struct TokensManagementChooserView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: TokensManagementFlowCoordinator

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 0) {
            row(
                icon: Assets.plus24,
                title: Localization.addAndManageSheetManageTitle,
                subtitle: Localization.addAndManageSheetManageSubtitle,
                action: viewModel.openAddTokens
            )
            .accessibilityIdentifier(TokensManagementChooserAccessibilityIdentifiers.addTokensRow)

            row(
                icon: Assets.OrganizeTokens.filterIcon,
                title: Localization.organizeTokensTitle,
                subtitle: Localization.addAndManageSheetOrganizeSubtitle,
                action: viewModel.openOrganize
            )
            .accessibilityIdentifier(TokensManagementChooserAccessibilityIdentifiers.organizeTokensRow)
        }
        .background(
            RoundedRectangle(cornerRadius: Constants.rowCornerRadius, style: .continuous)
                .fill(Colors.Background.action)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Sub Views

    private func row(icon: ImageType, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                iconView(icon: icon)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
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
                .fill(Colors.Icon.accent.opacity(0.1))
                .frame(width: Constants.iconContainerSize, height: Constants.iconContainerSize)

            icon.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundStyle(Colors.Icon.accent)
        }
    }
}

// MARK: - Constants

private extension TokensManagementChooserView {
    enum Constants {
        static let iconContainerSize: CGFloat = 36
        static let iconCornerRadius: CGFloat = 18
        static let iconSize: CGFloat = 24
        static let rowCornerRadius: CGFloat = 14
    }
}
