//
//  MobileImportWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct MobileImportWalletView: View {
    typealias ViewModel = MobileImportWalletViewModel

    @ObservedObject var viewModel: ViewModel

    @ScaledMetric var iconSide: CGFloat = Layout.iconSide

    var body: some View {
        content
            .padding(Layout.contentPadding)
    }
}

// MARK: - Subviews

private extension MobileImportWalletView {
    var content: some View {
        VStack(spacing: .zero) {
            navigation

            icon
                .padding(.top, Layout.iconTopPadding)

            description
                .padding(.top, Layout.descriptionTopPadding)

            actions
                .padding(.top, Layout.actionsTopPadding)
        }
    }

    var navigation: some View {
        NavigationBarButton.close(action: viewModel.onCloseTap)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .redesigned()
    }

    var icon: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Color.bgStatusInfoSubtle)

            DesignSystem.Icons.ArrowDownload.regular24.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconBrand)
        }
        .frame(size: CGSize(bothDimensions: iconSide))
    }

    var description: some View {
        let description = viewModel.description

        return VStack(spacing: Layout.descriptionSpacing) {
            Text(description.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)

            Text(description.subtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var actions: some View {
        VStack(spacing: Layout.actionsSpacing) {
            recoveryPhraseButton
            iCloudBackupButton
        }
    }

    var recoveryPhraseButton: some View {
        Button(
            label: viewModel.recoveryPhraseTitle,
            accessibilityLabel: nil,
            action: viewModel.onRecoveryPhraseTap
        )
        .styleType(.secondary)
        .size(.x12)
        .horizontalLayout(.infinity)
        .accessibilityIdentifier(OnboardingAccessibilityIdentifiers.mobileImportWalletRecoveryPhraseButton)
    }

    var iCloudBackupButton: some View {
        let state = viewModel.iCloudBackupState
        return Button(
            label: state.title,
            accessibilityLabel: nil,
            action: state.action
        )
        .styleType(.secondary)
        .size(.x12)
        .horizontalLayout(.infinity)
        .isLoading(state.isLoading)
        .disabled(!state.isEnabled)
        .accessibilityIdentifier(OnboardingAccessibilityIdentifiers.mobileImportWalletICloudBackupButton)
    }
}

// MARK: - Constants

private extension MobileImportWalletView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let iconSide: CGFloat = 72
        static let iconTopPadding: CGFloat = 32
        static let descriptionSpacing: CGFloat = 8
        static let descriptionTopPadding: CGFloat = 32
        static let actionsTopPadding: CGFloat = 48
        static let actionsSpacing: CGFloat = 8
    }
}
