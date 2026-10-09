//
//  WelcomeImportSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct WelcomeImportSheetView: View {
    @ObservedObject var viewModel: WelcomeImportSheetViewModel

    var body: some View {
        FloatingSheetContentWithHeader(
            headerConfig: .init(
                title: "",
                backAction: viewModel.onBack,
                closeAction: viewModel.onClose
            )
        ) {
            VStack(spacing: 0) {
                badge

                titleBlock
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                VStack(spacing: 8) {
                    ForEach(viewModel.items) { item in
                        row(for: item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
        }
    }

    private var badge: some View {
        DesignSystem.Icons.ArrowDownload.regular24.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconBrand)
            .frame(width: 72, height: 72)
            .background(DesignSystem.Color.bgStatusInfoSubtle, in: Circle())
            .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text(viewModel.title)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)

            if let subtitle = viewModel.subtitle {
                Text(subtitle)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func row(for item: WelcomeImportSheetItem) -> some View {
        TangemUI.Button(
            label: item.title,
            accessibilityLabel: nil,
            action: item.action
        )
        .styleType(.secondary(.default))
        .horizontalLayout(.infinity)
        .size(.x12)
        .loading(.spinner(if: item.isLoading))
        .disabled(!item.isEnabled)
        .accessibilityIdentifier(rowAccessibilityIdentifier(for: item))
    }

    private func rowAccessibilityIdentifier(for item: WelcomeImportSheetItem) -> String? {
        switch item.id {
        case WelcomeImportSheetViewModel.ItemID.recovery: OnboardingAccessibilityIdentifiers.welcomeImportSheetRecoveryPhraseButton
        case WelcomeImportSheetViewModel.ItemID.iCloud: OnboardingAccessibilityIdentifiers.welcomeImportSheetICloudBackupButton
        default: nil
        }
    }
}
