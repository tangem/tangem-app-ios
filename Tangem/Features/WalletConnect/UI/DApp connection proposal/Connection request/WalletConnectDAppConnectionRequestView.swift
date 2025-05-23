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
            VStack(spacing: Layout.contentSectionsSpacing) {
                dAppAndConnectionRequestSections
                walletAndNetworksSections
            }
            .padding(.horizontal, 16)
            .padding(.top, Layout.contentTopPadding)
            .padding(.bottom, Layout.contentBottomPadding)
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
            WalletConnectDAppDescriptionView(viewModel: viewModel.state.dAppDescriptionSection)
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

extension WalletConnectDAppConnectionRequestView {
    private enum Layout {
        /// 52
        static let navigationBarHeight = WalletConnectNavigationBarView.Layout.topPadding + WalletConnectNavigationBarView.Layout.height
        /// 12
        static let contentTopPadding: CGFloat = 12
        /// 14
        static let contentSectionsSpacing: CGFloat = 14
        /// 8
        static let contentBottomPadding: CGFloat = 8
        /// 16
        static let buttonsPadding: CGFloat = 16

        static let scrollViewCoordinateSpace = "WalletConnectDAppConnectionRequestView.ScrollView"
    }
}
