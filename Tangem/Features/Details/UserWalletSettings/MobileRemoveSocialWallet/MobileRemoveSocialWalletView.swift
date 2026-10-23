//
//  MobileRemoveSocialWalletView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileRemoveSocialWalletView: View {
    typealias ViewModel = MobileRemoveSocialWalletViewModel

    @ObservedObject var viewModel: ViewModel

    @ScaledMetric private var iconSide: CGFloat = Layout.iconSide
    @ScaledMetric private var titleTopPadding: CGFloat = Layout.titleTopPadding
    @ScaledMetric private var subtitleTopPadding: CGFloat = Layout.subtitleTopPadding

    var body: some View {
        content
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, Layout.bottomPadding)
            .background(DesignSystem.Color.bgPrimary)
            .overlay { loadingOverlay }
            .topNavigation(
                title: viewModel.navigationTitle,
                leading: .custom(.back(action: viewModel.onBackTap))
            )
    }
}

// MARK: - Subviews

private extension MobileRemoveSocialWalletView {
    @ViewBuilder
    var loadingOverlay: some View {
        if viewModel.isLoading {
            ZStack {
                DesignSystem.Color.overlayModal
                    .ignoresSafeArea()

                Loader()
                    .loaderColor(DesignSystem.Color.iconSecondary)
                    .loaderSize(.size32)
            }
        }
    }

    var content: some View {
        VStack(spacing: .zero) {
            Spacer()

            attention(item: viewModel.attentionItem)
                .padding(.horizontal, Layout.attentionHorizontalPadding)

            Spacer()

            marks
                .padding(.horizontal, Layout.marksHorizontalPadding)

            action(item: viewModel.actionItem)
                .padding(.top, Layout.actionTopPadding)
        }
    }

    func attention(item: ViewModel.AttentionItem) -> some View {
        VStack(spacing: .zero) {
            Assets.attentionRed.image
                .resizable()
                .frame(width: iconSide, height: iconSide)

            Text(item.title)
                .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                .padding(.top, titleTopPadding)

            Text(item.subtitle)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, subtitleTopPadding)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var marks: some View {
        MobileRemoveWalletCheckmarkRow(
            title: viewModel.backupCheckTitle,
            isChecked: $viewModel.isBackupChecked
        )
        .disabled(viewModel.isLoading)
    }

    func action(item: ViewModel.ActionItem) -> some View {
        Button(
            label: item.title,
            accessibilityLabel: nil,
            action: item.handler
        )
        .styleType(.primary)
        .size(.x12)
        .horizontalLayout(.infinity)
        .loading(.spinner(if: viewModel.isLoading))
        .disabled(!viewModel.isActionEnabled)
        .confirmationDialog(viewModel: $viewModel.confirmationDialog)
    }
}

// MARK: - Layout

private extension MobileRemoveSocialWalletView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 6
        static let attentionHorizontalPadding: CGFloat = 24
        static let iconSide: CGFloat = 72
        static let titleTopPadding: CGFloat = 20
        static let subtitleTopPadding: CGFloat = 12
        static let marksHorizontalPadding: CGFloat = 8
        static let actionTopPadding: CGFloat = 24
    }
}
