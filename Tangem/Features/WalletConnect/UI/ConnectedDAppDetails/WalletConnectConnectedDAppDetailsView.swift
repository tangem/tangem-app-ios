//
//  WalletConnectConnectedDAppDetailsView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectConnectedDAppDetailsView: View {
    @ObservedObject var viewModel: WalletConnectConnectedDAppDetailsViewModel

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: Layout.sectionsSpacing) {
                dAppAndWalletSection
                connectedNetworksSection(viewModel.state.connectedNetworksSection)
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            navigationBar
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            disconnectButton
        }
        .scrollBounceBehaviorBackport(.basedOnSize)
        .background(Colors.Background.tertiary)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: desiredContentHeight)
    }

    private var navigationBar: some View {
        WalletConnectNavigationBarView(
            title: viewModel.state.navigationBar.title,
            subtitle: viewModel.state.navigationBar.connectedTime,
            closeButtonAction: { viewModel.handle(viewEvent: .closeButtonTapped) }
        )
        .padding(.bottom, Layout.NavigationBar.bottomPadding)
        .background {
            ListFooterOverlayShadowView(
                colors: [
                    Colors.Background.tertiary,
                    Colors.Background.tertiary,
                    Colors.Background.tertiary.opacity(0.95),
                    Colors.Background.tertiary.opacity(0.0),
                ]
            )
        }
    }

    private var dAppAndWalletSection: some View {
        VStack(spacing: .zero) {
            dAppSection

            if let walletSectionState = viewModel.state.walletSection {
                Divider()
                    .frame(height: Layout.DAppAndWalletSection.dilimiterHeight)
                    .overlay(Colors.Stroke.primary)

                walletSection(walletSectionState)
            }
        }
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var dAppSection: some View {
        HStack(spacing: 16) {
            viewModel.state.dAppDescriptionSection.fallbackIconAsset.image
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(Colors.Icon.accent)
                .frame(width: 56, height: 56)
                .background(Colors.Icon.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.state.dAppDescriptionSection.name)
                    .lineLimit(1)
                    .style(Fonts.Bold.title3.weight(.semibold), color: Colors.Text.primary1)

                Text(viewModel.state.dAppDescriptionSection.domain)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: Layout.DAppAndWalletSection.dAppSectionHeight)
        .padding(.horizontal, 14)
        .padding(.vertical, Layout.DAppAndWalletSection.dAppVerticalPadding)
    }

    private func walletSection(_ walletSectionState: WalletConnectConnectedDAppDetailsViewState.WalletSection) -> some View {
        HStack(spacing: .zero) {
            HStack(spacing: 4) {
                walletSectionState.labelAsset.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Colors.Icon.accent)

                Text(walletSectionState.labelText)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
            }

            Spacer(minLength: 12)

            Text(walletSectionState.walletName)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
        }
        .frame(height: Layout.DAppAndWalletSection.walletSectionHeight)
        .padding(.horizontal, 14)
        .padding(.vertical, Layout.DAppAndWalletSection.walletVerticalPadding)
    }

    @ViewBuilder
    private func connectedNetworksSection(_ state: WalletConnectConnectedDAppDetailsViewState.ConnectedNetworksSection?) -> some View {
        if let state {
            LazyVStack(alignment: .leading, spacing: .zero) {
                Text(state.title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .frame(height: Layout.ConnectedNetworks.titleHeight)

                Spacer()
                    .frame(height: Layout.ConnectedNetworks.spacing)

                ForEach(state.blockchains, content: blockchainRow)
            }
            .padding(.top, Layout.ConnectedNetworks.titleTopPadding)
            .padding(.horizontal, 14)
            .background(Colors.Background.action)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func blockchainRow(_ blockchain: WalletConnectConnectedDAppDetailsViewState.BlockchainRowItem) -> some View {
        HStack(spacing: 12) {
            blockchain.asset.image
                .resizable()
                .frame(width: 24, height: 24)

            HStack(spacing: 4) {
                Text(blockchain.name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(blockchain.currencySymbol)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: Layout.ConnectedNetworks.rowHeight)
    }

    private var disconnectButton: some View {
        MainButton(
            title: viewModel.state.disconnectButton.title,
            subtitle: nil,
            icon: nil,
            style: .secondary,
            size: .default,
            isLoading: viewModel.state.disconnectButton.isLoading,
            isDisabled: false,
            handleActionWhenDisabled: false,
            action: {
                viewModel.handle(viewEvent: .disconnectButtonTapped)
            }
        )
        .padding(.top, Layout.DisconnectButton.topPadding)
        .padding(.bottom, Layout.DisconnectButton.bottomPadding)
        .background {
            ListFooterOverlayShadowView(
                colors: [
                    Colors.Background.tertiary.opacity(0.0),
                    Colors.Background.tertiary.opacity(0.95),
                    Colors.Background.tertiary,
                ]
            )
            .padding(.top, -12)
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private var desiredContentHeight: CGFloat {
        var desiredHeight = Layout.NavigationBar.topPadding
            + Layout.NavigationBar.height
            + Layout.NavigationBar.bottomPadding
            + Layout.DAppAndWalletSection.dAppVerticalPadding
            + Layout.DAppAndWalletSection.dAppSectionHeight
            + Layout.DAppAndWalletSection.dAppVerticalPadding

        if viewModel.state.walletSection != nil {
            desiredHeight += Layout.DAppAndWalletSection.dilimiterHeight
                + Layout.DAppAndWalletSection.walletVerticalPadding
                + Layout.DAppAndWalletSection.walletSectionHeight
                + Layout.DAppAndWalletSection.walletVerticalPadding
        }

        desiredHeight += Layout.sectionsSpacing

        if let connectedNetworksSection = viewModel.state.connectedNetworksSection {
            desiredHeight += Layout.ConnectedNetworks.titleTopPadding
                + Layout.ConnectedNetworks.titleHeight
                + Layout.ConnectedNetworks.spacing
                + Layout.ConnectedNetworks.rowHeight * CGFloat(connectedNetworksSection.blockchains.count)
        }

        desiredHeight += Layout.DisconnectButton.topPadding
            + MainButton.Size.default.height
            + Layout.DisconnectButton.bottomPadding

        return desiredHeight
    }
}

extension WalletConnectConnectedDAppDetailsView {
    private enum Layout {
        enum NavigationBar {
            /// 8
            static let topPadding = WalletConnectNavigationBarView.Layout.topPadding
            /// 12
            static let bottomPadding: CGFloat = 12
            /// 44
            static let height = WalletConnectNavigationBarView.Layout.height
        }

        enum DAppAndWalletSection {
            /// 16
            static let dAppVerticalPadding: CGFloat = 16
            /// 56
            static let dAppSectionHeight: CGFloat = 56
            /// 1
            static let dilimiterHeight: CGFloat = 1
            /// 12
            static let walletVerticalPadding: CGFloat = 12
            /// 24
            static let walletSectionHeight: CGFloat = 24
        }

        enum ConnectedNetworks {
            /// 12
            static let titleTopPadding: CGFloat = 12
            /// 18
            static let titleHeight: CGFloat = 18
            /// 8
            static let spacing: CGFloat = 8
            /// 52
            static let rowHeight: CGFloat = 52
        }

        enum DisconnectButton {
            /// 24
            static let topPadding: CGFloat = 24
            /// 16
            static let bottomPadding: CGFloat = 16
        }

        /// 16
        static let horizontalPadding: CGFloat = 16
        /// 14
        static let sectionsSpacing: CGFloat = 14
    }
}
