//
//  WalletConnectConnectedDAppDetailsView.swift
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

struct WalletConnectConnectedDAppDetailsView: View {
    @ObservedObject var viewModel: WalletConnectConnectedDAppDetailsViewModel
    let kingfisherImageCache: ImageCache

    @State private var navigationBarBottomSeparatorIsVisible = false

    var body: some View {
        ScrollView(.vertical) {
            contentStateView
                .readGeometry(
                    \.frame.minY,
                    inCoordinateSpace: .named(Layout.scrollViewCoordinateSpace),
                    throttleInterval: .proMotion,
                    onChange: updateNavigationBarBottomSeparatorVisibility
                )
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            header
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            footer
        }
        .scrollBounceBehaviorBackport(.basedOnSize)
        .coordinateSpace(name: Layout.scrollViewCoordinateSpace)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.tertiary
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
            configuration.backgroundInteractionBehavior = .consumeTouches
        }
    }

    private var contentStateView: some View {
        ZStack {
            switch viewModel.state {
            case .dAppDetails(let viewState):
                VStack(spacing: 14) {
                    dAppAndWalletSection(viewState)
                    dAppVerificationWarningSection(viewState)
                    connectedNetworksSection(viewState)
                }
                .padding(.top, Layout.contentTopPadding)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .onAppear {
                    viewModel.handle(viewEvent: .dAppDetailsAppeared)
                }
                .transition(.content)

            case .verifiedDomain(let viewModel):
                WalletConnectDAppDomainVerificationView(viewModel: viewModel)
                    .transition(.content)
            }
        }
    }

    private var header: some View {
        let title: String?
        let subtitle: String?
        let backgroundColor: Color
        let closeButtonAction: () -> Void

        switch viewModel.state {
        case .dAppDetails(let viewState):
            title = viewState.navigationBar.title
            subtitle = viewState.navigationBar.connectedTime
            backgroundColor = Colors.Background.tertiary
            closeButtonAction = { viewModel.handle(viewEvent: .closeButtonTapped) }

        case .verifiedDomain(let viewModel):
            title = nil
            subtitle = nil
            backgroundColor = Color.clear
            closeButtonAction = { viewModel.handle(viewEvent: .navigationCloseButtonTapped) }
        }

        return WalletConnectNavigationBarView(
            title: title,
            subtitle: subtitle,
            backgroundColor: backgroundColor,
            bottomSeparatorLineIsVisible: navigationBarBottomSeparatorIsVisible,
            closeButtonAction: closeButtonAction
        )
        .id(viewModel.state.id)
        .transition(.opacity)
        .transformEffect(.identity)
        .animation(.headerOpacity.delay(0.2), value: viewModel.state.id)
    }

    private func dAppAndWalletSection(_ viewState: WalletConnectConnectedDAppDetailsViewState.DAppDetails) -> some View {
        VStack(spacing: .zero) {
            WalletConnectDAppDescriptionView(
                viewModel: viewState.dAppDescriptionSection,
                kingfisherImageCache: kingfisherImageCache,
                verifiedDomainTapAction: {
                    viewModel.handle(viewEvent: .verifiedDomainIconTapped)
                }
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 16)

            if let walletSectionState = viewState.walletSection {
                Divider()
                    .frame(height: 1)
                    .overlay(Colors.Stroke.primary)

                walletSection(walletSectionState)
            }
        }
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func dAppVerificationWarningSection(_ viewState: WalletConnectConnectedDAppDetailsViewState.DAppDetails) -> some View {
        if let dAppVerificationWarningSection = viewState.dAppVerificationWarningSection {
            WalletConnectWarningNotificationView(viewModel: dAppVerificationWarningSection)
        }
    }

    private func walletSection(_ walletSectionState: WalletConnectConnectedDAppDetailsViewState.DAppDetails.WalletSection) -> some View {
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
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private func connectedNetworksSection(_ viewState: WalletConnectConnectedDAppDetailsViewState.DAppDetails) -> some View {
        if let connectedNetworksSection = viewState.connectedNetworksSection {
            LazyVStack(alignment: .leading, spacing: .zero) {
                Text(connectedNetworksSection.headerTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                ForEach(connectedNetworksSection.blockchains, content: blockchainRow)
            }
            .padding(.horizontal, 14)
            .background(Colors.Background.action)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func blockchainRow(_ blockchain: WalletConnectConnectedDAppDetailsViewState.DAppDetails.BlockchainRowItem) -> some View {
        HStack(spacing: 12) {
            blockchain.iconAsset.image
                .resizable()
                .frame(width: 24, height: 24)

            HStack(alignment: .bottom, spacing: 4) {
                Text(blockchain.name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(blockchain.currencySymbol)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                Spacer(minLength: .zero)
            }
        }
        .lineLimit(1)
        .padding(.vertical, 14)
    }

    private var footer: some View {
        ZStack {
            switch viewModel.state {
            case .dAppDetails(let viewState):
                dAppDetailsFooter(viewState)
                    .transition(.footer)

            case .verifiedDomain(let viewModel):
                verifiedDomainFooter(viewModel)
                    .transition(.footer)
            }
        }
        .background {
            ListFooterOverlayShadowView(
                colors: [
                    Colors.Background.tertiary.opacity(0.0),
                    Colors.Background.tertiary.opacity(0.95),
                    Colors.Background.tertiary,
                ]
            )
            .padding(.top, 6)
        }
        .animation(.contentFrameUpdate, value: viewModel.state.id)
    }

    private func dAppDetailsFooter(_ viewState: WalletConnectConnectedDAppDetailsViewState.DAppDetails) -> some View {
        MainButton(
            title: viewState.disconnectButton.title,
            style: .secondary,
            isLoading: viewState.disconnectButton.isLoading,
            action: {
                viewModel.handle(viewEvent: .disconnectButtonTapped)
            }
        )
        .padding(16)
    }

    private func verifiedDomainFooter(_ viewModel: WalletConnectDAppDomainVerificationViewModel) -> some View {
        VStack(spacing: 8) {
            ForEach(viewModel.state.buttons, id: \.self) { buttonState in
                MainButton(
                    title: buttonState.title,
                    style: buttonState.style.toMainButtonStyle,
                    isLoading: buttonState.isLoading,
                    action: {
                        viewModel.handle(viewEvent: .actionButtonTapped(buttonState.role))
                    }
                )
            }
        }
        .padding(16)
    }

    private func updateNavigationBarBottomSeparatorVisibility(_ scrollViewMinY: CGFloat) {
        navigationBarBottomSeparatorIsVisible = scrollViewMinY < Layout.navigationBarHeight - Layout.contentTopPadding
    }
}

extension WalletConnectConnectedDAppDetailsView {
    private enum Layout {
        /// 52
        static let navigationBarHeight = WalletConnectNavigationBarView.Layout.topPadding + WalletConnectNavigationBarView.Layout.height
        /// 12
        static let contentTopPadding: CGFloat = 12

        static let scrollViewCoordinateSpace = "WalletConnectConnectedDAppDetailsView.ScrollView"
    }
}

private extension Animation {
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.2)
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
    static let footerOpacity = Animation.curve(.easeOutEmphasized, duration: 0.3)
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )

    static let footer = AnyTransition.asymmetric(
        insertion: .offset(y: 200).combined(with: .opacity.animation(.footerOpacity.delay(0.2))),
        removal: .offset(y: 200).combined(with: .opacity.animation(.footerOpacity))
    )
}

private extension WalletConnectConnectedDAppDetailsViewState {
    var id: String {
        switch self {
        case .dAppDetails:
            "dAppDetails"
        case .verifiedDomain:
            "verifiedDomain"
        }
    }
}

private extension WalletConnectDAppDomainVerificationViewState.Button.Style {
    var toMainButtonStyle: MainButton.Style {
        switch self {
        case .primary: .primary
        case .secondary: .secondary
        }
    }
}
