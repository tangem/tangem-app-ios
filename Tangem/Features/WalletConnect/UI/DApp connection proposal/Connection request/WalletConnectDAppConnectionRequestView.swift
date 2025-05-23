//
//  WalletConnectDAppConnectionRequestView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import HotSwiftUI

struct WalletConnectDAppConnectionRequestView: View {
    @ObservedObject var viewModel: WalletConnectDAppConnectionRequestViewModel

    @State private var navigationBarBottomSeparatorIsVisible = false
    @State private var scrollViewMaxHeight: CGFloat = 0

    @ObserveInjection var io

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 14) {
                dAppAndConnectionRequestSections
                dAppVerificationWarningSection
                walletAndNetworksSections
            }
            .padding(.horizontal, 16)
            .padding(.top, Layout.contentTopPadding)
            .padding(.bottom, 8)
            .readGeometry(\.self, inCoordinateSpace: .named(Layout.scrollViewCoordinateSpace), throttleInterval: .zero) { geometryInfo in
                withAnimation(WalletConnectDAppConnectionRequestSectionView.Animations.sectionSlideInsertion) {
                    updateScrollViewMaxHeight(geometryInfo.size.height)
                }

                updateNavigationBarBottomSeparatorVisibility(geometryInfo.frame.minY)
            }
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            navigationBar
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            buttons
        }
        .scrollBounceBehaviorBackport(.basedOnSize)
        .frame(maxHeight: scrollViewMaxHeight)
        .coordinateSpace(name: Layout.scrollViewCoordinateSpace)
        .enableInjection()
    }

    private var navigationBar: some View {
        WalletConnectNavigationBarView(
            title: viewModel.state.navigationTitle,
            subtitle: nil,
            bottomSeparatorLineIsVisible: navigationBarBottomSeparatorIsVisible,
            backButtonAction: nil,
            closeButtonAction: { viewModel.handle(viewEvent: .navigationCloseButtonTapped) }
        )
    }

    private var dAppAndConnectionRequestSections: some View {
        VStack(spacing: .zero) {
            WalletConnectDAppDescriptionView(
                viewModel: viewModel.state.dAppDescriptionSection,
                verifiedDomainTapAction: { viewModel.handle(viewEvent: .verifiedDomainIconTapped) }
            )
            .padding(.vertical, 16)
            .padding(.horizontal, 14)

            Divider()
                .frame(height: 1)
                .overlay(Colors.Stroke.primary)

            WalletConnectDAppConnectionRequestSectionView(
                viewModel: viewModel.state.connectionRequestSection,
                tapAction: { viewModel.handle(viewEvent: .connectionRequestSectionHeaderTapped) }
            )
            .padding(.horizontal, 14)
        }
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var dAppVerificationWarningSection: some View {
        if let dAppVerificationWarningSection = viewModel.state.dAppVerificationWarningSection {
            HStack(alignment: .top, spacing: 12) {
                dAppVerificationWarningSection.iconAsset.image
                    .resizable()
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(dAppVerificationWarningSection.title)
                        .style(Fonts.Bold.footnote, color: dAppVerificationWarningSection.severity.tintColor)

                    Text(dAppVerificationWarningSection.body)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 12)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            .background(dAppVerificationWarningSection.severity.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
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

            networksSection
                .padding(.horizontal, 14)
        }
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var walletSection: some View {
        Button(action: { viewModel.handle(viewEvent: .walletRowTapped) }) {
            HStack(spacing: .zero) {
                viewModel.state.walletSection.iconAsset.image
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Colors.Icon.accent)

                Spacer()
                    .frame(width: 8)

                Text(viewModel.state.walletSection.label)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)

                Spacer(minLength: .zero)

                Text(viewModel.state.walletSection.walletName)
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                    .padding(.horizontal, 4)

                viewModel.state.walletSection.trailingIconAsset?.image
                    .resizable()
                    .frame(width: 18, height: 24)
                    .foregroundStyle(Colors.Icon.informative)
            }
            .frame(height: 46)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var networksSection: some View {
        Button(action: { viewModel.handle(viewEvent: .networksRowTapped) }) {
            HStack(spacing: .zero) {
                viewModel.state.networksSection.iconAsset.image
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Colors.Icon.accent)

                Spacer()
                    .frame(width: 8)

                Text(viewModel.state.networksSection.label)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)

                Spacer()
            }
            .frame(height: 46)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var buttons: some View {
        HStack(spacing: 8) {
            MainButton(
                title: viewModel.state.cancelButtonTitle,
                subtitle: nil,
                icon: nil,
                style: .secondary,
                size: .default,
                isLoading: false,
                isDisabled: false,
                handleActionWhenDisabled: false,
                action: {
                    viewModel.handle(viewEvent: .cancelButtonTapped)
                }
            )

            MainButton(
                title: viewModel.state.connectButtonTitle,
                subtitle: nil,
                icon: nil,
                style: .primary,
                size: .default,
                isLoading: false,
                isDisabled: false,
                handleActionWhenDisabled: false,
                action: {
                    viewModel.handle(viewEvent: .connectButtonTapped)
                }
            )
        }
        .padding(Layout.buttonsPadding)
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
    }

    private func updateScrollViewMaxHeight(_ desiredContentHeight: CGFloat) {
        scrollViewMaxHeight = Layout.navigationBarHeight
            + desiredContentHeight
            + Layout.buttonsPadding
            + MainButton.Size.default.height
            + Layout.buttonsPadding
    }

    private func updateNavigationBarBottomSeparatorVisibility(_ scrollViewMinY: CGFloat) {
        navigationBarBottomSeparatorIsVisible = scrollViewMinY < Layout.navigationBarHeight - Layout.contentTopPadding
    }
}

private extension WalletConnectDAppConnectionRequestViewState.DAppVerificationWarningSection.Severity {
    var tintColor: Color {
        switch self {
        case .warning: Colors.Text.primary1
        case .critical: Colors.Icon.warning
        }
    }

    var backgroundColor: Color {
        switch self {
        case .warning: Colors.Button.disabled
        case .critical: Colors.Icon.warning.opacity(0.1)
        }
    }
}

extension WalletConnectDAppConnectionRequestView {
    private enum Layout {
        /// 52
        static let navigationBarHeight = WalletConnectNavigationBarView.Layout.topPadding + WalletConnectNavigationBarView.Layout.height
        /// 12
        static let contentTopPadding: CGFloat = 12
        /// 16
        static let buttonsPadding: CGFloat = 16

        static let scrollViewCoordinateSpace = "WalletConnectDAppConnectionRequestView.ScrollView"
    }
}
