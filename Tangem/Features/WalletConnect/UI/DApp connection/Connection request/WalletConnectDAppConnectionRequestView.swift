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
                .overlay(Colors.Stroke.primary)

            WalletConnectDAppConnectionRequestView.ConnectionRequestSection(
                viewModel: viewModel.state.connectionRequestSection,
                tapAction: { viewModel.handle(viewEvent: .connectionRequestSectionHeaderTapped) }
            )
            .compositingGroup()
            .padding(.horizontal, 14)
        }
        .background(Colors.Background.action)
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
            walletSection
                .padding(.horizontal, 14)

            Divider()
                .frame(height: 1)
                .overlay(Colors.Stroke.primary)
                .padding(.leading, 46)
                .padding(.trailing, 14)

            networkSection
                .padding(.horizontal, 14)

            if let networksWarningSection = viewModel.state.networksWarningSection {
                Divider()
                    .frame(height: 1)
                    .overlay(Colors.Stroke.primary)

                WalletConnectWarningNotificationView(viewModel: networksWarningSection)
            }
        }
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Wallet section

    private var walletSection: some View {
        BaseOneLineRowButton(
            icon: viewModel.state.walletSection.iconAsset,
            title: viewModel.state.walletSection.label,
            shouldShowTrailingIcon: viewModel.state.walletSection.selectionIsAvailable,
            action: { viewModel.handle(viewEvent: .walletRowTapped) },
            trailingView: { walletSectionTrailingView }
        )
        .verticalPadding(12)
        .accessibilityIdentifier(WalletConnectAccessibilityIdentifiers.walletLabel)
        .allowsHitTesting(viewModel.state.walletSection.selectionIsAvailable)
    }

    private var walletSectionTrailingView: some View {
        HStack(spacing: 0) {
            Text(viewModel.state.walletSection.selectedUserWalletName)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                .padding(.horizontal, 4)
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
                SkeletonView()
                    .frame(width: 88, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

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
                .foregroundStyle(Colors.Icon.informative)
        }
    }

    private func availableSelectionTrailingView(
        _ availableSelectionMode: WalletConnectDAppConnectionRequestViewState.NetworksSection.AvailableSelectionMode
    ) -> some View {
        HStack(spacing: -8) {
            ForEach(availableSelectionMode.blockchainLogoAssets.indexed(), id: \.0) { index, blockchainLogoAsset in
                ZStack {
                    Circle()
                        .fill(Colors.Background.action)
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
                        .fill(Colors.Background.action)
                        .frame(width: 24, height: 24)

                    Circle()
                        .fill(Colors.Icon.primary1.opacity(0.1))
                        .frame(width: 24, height: 24)

                    Circle()
                        .strokeBorder(Colors.Background.action, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    Text(remainingBlockchainsCounter)
                        .style(Fonts.Bold.caption2, color: Colors.Text.secondary)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}
