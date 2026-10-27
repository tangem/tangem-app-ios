//
//  WalletConnectDAppConnectionRequestView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers
import TangemAccounts

struct WalletConnectDAppConnectionRequestView: View {
    @ObservedObject var viewModel: WalletConnectDAppConnectionRequestViewModel
    let kingfisherImageCache: ImageCache

    var body: some View {
        VStack(spacing: 14) {
            dAppAndConnectionRequestSections
            dAppVerificationWarningSection
            walletAndNetworksSections
        }
        .padding(.horizontal, 16)
        .transformEffect(.identity)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var dAppAndConnectionRequestSections: some View {
        VStack(spacing: .zero) {
            EntitySummaryView(
                viewState: viewModel.state.dAppDescriptionSection,
                kingfisherImageCache: kingfisherImageCache
            )
            .padding(.vertical, 16)
            .padding(.horizontal, 14)

            Divider()
                .frame(height: 1)
                .overlay(DesignSystem.Color.borderSecondary)

            WalletConnectDAppConnectionRequestView.ConnectionRequestSection(
                viewModel: viewModel.state.connectionRequestSection,
                tapAction: { viewModel.handle(viewEvent: .connectionRequestSectionHeaderTapped) }
            )
            .compositingGroup()
            .padding(.horizontal, 14)
        }
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var dAppVerificationWarningSection: some View {
        if let dAppVerificationWarningSection = viewModel.state.dAppVerificationWarningSection {
            WalletConnectWarningNotificationView(viewModel: dAppVerificationWarningSection)
        }
    }

    private var walletAndNetworksSections: some View {
        VStack(spacing: .zero) {
            accountSection
                .padding(.horizontal, 14)

            Divider()
                .frame(height: 1)
                .overlay(DesignSystem.Color.borderSecondary)
                .padding(.leading, 46)
                .padding(.trailing, 14)

            networkSection
                .padding(.horizontal, 14)

            if let networksWarningSection = viewModel.state.networksWarningSection {
                Divider()
                    .frame(height: 1)
                    .overlay(DesignSystem.Color.borderSecondary)

                WalletConnectWarningNotificationView(viewModel: networksWarningSection)
            }
        }
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Account Section

    @ViewBuilder
    private var accountSection: some View {
        if let connectionTargetSection = viewModel.state.connectionTargetSection {
            let label = switch connectionTargetSection.target {
            case .wallet(let target):
                target.label
            case .account(let target):
                target.label
            }

            BaseOneLineRowButton(
                icon: connectionTargetSection.iconAsset,
                shouldShowTrailingIcon: connectionTargetSection.selectionIsAvailable,
                action: { viewModel.handle(viewEvent: .accountRowTapped) },
                titleView: {
                    switch connectionTargetSection.state {
                    case .loading:
                        Shimmer().variant(.custom(width: 64, height: 24, cornerRadius: 8))
                    case .content:
                        Text(label)
                            .style(Fonts.Regular.body, color: DesignSystem.Color.textPrimary)
                            .lineLimit(1)
                    }
                },
                trailingView: {
                    switch connectionTargetSection.state {
                    case .loading:
                        Shimmer().variant(.custom(width: 88, height: 24, cornerRadius: 8))
                    case .content:
                        switch connectionTargetSection.target {
                        case .wallet:
                            Text(connectionTargetSection.targetName)
                                .style(Fonts.Regular.body, color: DesignSystem.Color.textSecondary)
                                .padding(.horizontal, 4)
                        case .account(let target):
                            accountTargetTrailingView(icon: target.icon, accountName: connectionTargetSection.targetName)
                        }
                    }
                }
            )
            .verticalPadding(12)
            .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.walletLabel)
            .allowsHitTesting(connectionTargetSection.selectionIsAvailable)
        }
    }

    private func accountTargetTrailingView(icon: AccountModel.Icon, accountName: String) -> some View {
        HStack(spacing: 6) {
            AccountIconView(
                data: AccountModelUtils.UI.iconViewData(icon: icon, accountName: accountName)
            )
            .settings(.smallSized)

            Text(accountName)
                .style(Fonts.Regular.body, color: DesignSystem.Color.textSecondary)
        }
    }

    // MARK: - Network section

    private var networkSection: some View {
        BaseOneLineRowButton(
            icon: viewModel.state.networksSection.iconAsset,
            title: viewModel.state.networksSection.label,
            shouldShowTrailingIcon: false, // Needed to fully control trailing icon from self-made view
            action: { viewModel.handle(viewEvent: .networksRowTapped) },
            trailingView: { networkSectionTrailingView }
        )
        .verticalPadding(12)
        .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.networksLabel)
        .allowsHitTesting(viewModel.state.networksSection.state != .loading)
    }

    private var networkSectionTrailingView: some View {
        HStack(spacing: 0) {
            switch viewModel.state.networksSection.state {
            case .loading:
                Shimmer().variant(.custom(width: 88, height: 24, cornerRadius: 8))

            case .content(let contentState):
                switch contentState.selectionMode {
                case .available(let availableSelectionMode):
                    availableSelectionTrailingView(availableSelectionMode)
                case .requiredNetworksAreMissing:
                    EmptyView()
                }
            }

            viewModel.state.networksSection.trailingIconAsset?.image
                .resizable()
                .frame(width: 18, height: 24)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
        }
    }

    private func availableSelectionTrailingView(
        _ availableSelectionMode: WalletConnectDAppConnectionRequestViewState.NetworksSection.AvailableSelectionMode
    ) -> some View {
        HStack(spacing: -8) {
            ForEach(indexed: availableSelectionMode.blockchainLogoAssets, id: \.0) { _, blockchainLogoAsset in
                ZStack {
                    Circle()
                        .fill(DesignSystem.Color.bgSecondary)
                        .frame(width: 24, height: 24)

                    blockchainLogoAsset.image
                        .resizable()
                        .clipShape(.circle)
                        .frame(width: 20, height: 20)
                }
            }

            if let remainingBlockchainsCounter = availableSelectionMode.remainingBlockchainsCounter {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Color.bgSecondary)
                        .frame(width: 24, height: 24)

                    Circle()
                        .fill(DesignSystem.Color.bgTransparentSecondary)
                        .frame(width: 24, height: 24)

                    Circle()
                        .strokeBorder(DesignSystem.Color.bgSecondary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    Text(remainingBlockchainsCounter)
                        .style(Fonts.Bold.caption2, color: DesignSystem.Color.textSecondary)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}
