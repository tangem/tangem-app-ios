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
                withAnimation(Animations.sectionSlideInsertion) {
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

            WalletConnectDAppConnectionRequestView.ConnectionRequestSection(
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

            WalletConnectDAppConnectionRequestView.NetworksSection(
                viewModel: viewModel.state.networksSection,
                tapAction: { viewModel.handle(viewEvent: .networksRowTapped) }
            )
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

                Text(viewModel.state.walletSection.selectedUserWalletName)
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

    private var buttons: some View {
        HStack(spacing: 8) {
            MainButton(
                title: viewModel.state.cancelButton.title,
                subtitle: nil,
                icon: nil,
                style: .secondary,
                size: .default,
                isLoading: viewModel.state.cancelButton.isLoading,
                handleActionWhenDisabled: false,
                action: {
                    viewModel.handle(viewEvent: .cancelButtonTapped)
                }
            )

            MainButton(
                title: viewModel.state.connectButton.title,
                subtitle: nil,
                icon: nil,
                style: .primary,
                size: .default,
                isLoading: viewModel.state.connectButton.isLoading,
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

extension WalletConnectDAppConnectionRequestView {
    enum Animations {
        struct Curve {
            let p1x: Double
            let p1y: Double
            let p2x: Double
            let p2y: Double

            static let primary = Curve(p1x: 0.76, p1y: 0, p2x: 0.24, p2y: 1)
            static let secondary = Curve(p1x: 0.65, p1y: 0, p2x: 0.35, p2y: 1)
        }

        static let sectionSlideInsertion = Animation.make(curve: .primary, duration: 0.5)
        static let sectionSlideRemoval = Animation.make(curve: .secondary, duration: 0.5)

        static let sectionOpacityInsertion = Self.sectionOpacityRemoval.delay(0.2)
        static let sectionOpacityRemoval = Animation.make(curve: .secondary, duration: 0.3)
    }
}

extension Animation {
    static func make(
        curve: WalletConnectDAppConnectionRequestView.Animations.Curve,
        duration: TimeInterval
    ) -> Animation {
        Animation.timingCurve(curve.p1x, curve.p1y, curve.p2x, curve.p2y, duration: duration)
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
