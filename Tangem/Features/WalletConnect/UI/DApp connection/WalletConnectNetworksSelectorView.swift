//
//  WalletConnectNetworksSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct WalletConnectNetworksSelectorView: View {
    @ObservedObject var viewModel: WalletConnectNetworksSelectorViewModel

    @State private var scrollViewMaxHeight: CGFloat = 0
    @State private var navigationBarBottomSeparatorIsVisible = false

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 14) {
                requiredNetworksAreUnavailableSection
                availableSection
                notAddedSection
            }
            .padding(.horizontal, 16)
            .padding(.top, Layout.contentTopPadding)
            .padding(.bottom, Layout.contentBottomPadding)
            .readGeometry(\.self, inCoordinateSpace: .named(Layout.scrollViewCoordinateSpace), throttleInterval: .proMotion) { geometryInfo in
                withAnimation(WalletConnectDAppConnectionRequestView.Animations.sectionSlideInsertion) {
                    updateScrollViewMaxHeight(geometryInfo.size.height)
                }

                updateNavigationBarBottomSeparatorVisibility(geometryInfo.frame.minY)
            }
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            navigationBar
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            doneButton
        }
        .scrollBounceBehaviorBackport(.basedOnSize)
        .frame(maxHeight: scrollViewMaxHeight)
        .coordinateSpace(name: Layout.scrollViewCoordinateSpace)
    }

    private var navigationBar: some View {
        WalletConnectNavigationBarView(
            title: viewModel.state.navigationBarTitle,
            bottomSeparatorLineIsVisible: navigationBarBottomSeparatorIsVisible,
            backButtonAction: { viewModel.handle(viewEvent: .navigationBackButtonTapped) }
        )
    }

    private var doneButton: some View {
        MainButton(
            title: viewModel.state.doneButton.title,
            style: .primary,
            isDisabled: !viewModel.state.doneButton.isEnabled,
            action: { viewModel.handle(viewEvent: .doneButtonTapped) }
        )
        .padding(Layout.doneButtonPadding)
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

    @ViewBuilder
    private var requiredNetworksAreUnavailableSection: some View {
        if let viewState = viewModel.state.requiredNetworksAreUnavailableSection {
            VStack(spacing: .zero) {
                WalletConnectWarningNotificationView(viewModel: viewState.notificationViewModel)

                Divider()
                    .frame(height: 1)
                    .overlay(Colors.Stroke.primary)

                ForEach(viewState.blockchains) { blockchainViewState in
                    missingRequiredBlockchainRow(blockchainViewState, requiredLabel: viewState.requiredLabel)
                        .padding(.horizontal, 14)
                }
            }
            .background(Colors.Background.action)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var availableSection: some View {
        if !viewModel.state.availableSection.blockchains.isEmpty {
            sectionContainer(viewModel.state.availableSection.headerTitle) {
                ForEach(indexed: viewModel.state.availableSection.blockchains.indexed(), content: availableBlockchainRow)
            }
        }
    }

    @ViewBuilder
    private var notAddedSection: some View {
        if !viewModel.state.notAddedSection.blockchains.isEmpty {
            sectionContainer(viewModel.state.notAddedSection.headerTitle) {
                ForEach(viewModel.state.notAddedSection.blockchains, content: notAddedBlockchainRow)
            }
        }
    }

    private func sectionContainer<Content: View>(_ headerTitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(headerTitle)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .offset(y: 2)
                .frame(height: Layout.sectionHeaderHeight)

            content()
        }
        .padding(.horizontal, 14)
        .background(Colors.Background.action)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func missingRequiredBlockchainRow(
        _ blockchainViewState: WalletConnectNetworksSelectorViewState.BlockchainViewState,
        requiredLabel: String
    ) -> some View {
        blockchainRow(blockchainViewState, blockchainIconBackgroundColor: Colors.Button.secondary, blockchainNameColor: Colors.Text.tertiary) {
            Text(requiredLabel)
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
        }
    }

    private func availableBlockchainRow(
        blockchainIndex: Int,
        viewState: WalletConnectNetworksSelectorViewState.AvailableSection.AvailableBlockchain
    ) -> some View {
        blockchainRow(viewState.blockchainViewState, blockchainIconBackgroundColor: .clear, blockchainNameColor: Colors.Text.primary1) {
            if viewModel.state.requiredNetworksAreUnavailableSection == nil {
                Toggle("", isOn: bindingFor(availableBlockchain: viewState, index: blockchainIndex))
                    .tint(Colors.Control.checked)
                    .disabled(viewState.isReadOnly)
            }
        }
    }

    private func notAddedBlockchainRow(viewState: WalletConnectNetworksSelectorViewState.BlockchainViewState) -> some View {
        blockchainRow(viewState, blockchainIconBackgroundColor: Colors.Button.secondary, blockchainNameColor: Colors.Text.tertiary) {
            EmptyView()
        }
    }

    private func blockchainRow<TrailingContent: View>(
        _ state: WalletConnectNetworksSelectorViewState.BlockchainViewState,
        blockchainIconBackgroundColor: Color,
        blockchainNameColor: Color,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) -> some View {
        HStack(spacing: .zero) {
            state.iconAsset.image
                .resizable()
                .frame(width: 24, height: 24)
                .background {
                    Circle()
                        .fill(blockchainIconBackgroundColor)
                }

            Spacer()
                .frame(width: 12)

            Text(state.name)
                .style(Fonts.Bold.subheadline, color: blockchainNameColor)

            Spacer()
                .frame(width: 4)

            Text(state.currencySymbol)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

            Spacer(minLength: .zero)

            trailingContent()
        }
        .lineLimit(1)
        .frame(height: Layout.blockchainRowHeight)
    }

    private func bindingFor(
        availableBlockchain: WalletConnectNetworksSelectorViewState.AvailableSection.AvailableBlockchain,
        index: Int
    ) -> Binding<Bool> {
        switch availableBlockchain {
        case .required:
            return .constant(true)

        case .optional(let optionalBlockchain):
            return Binding(
                get: { optionalBlockchain.isSelected },
                set: { isSelected in
                    viewModel.handle(
                        viewEvent: .optionalBlockchainSelectionChanged(index: index, isSelected: isSelected)
                    )
                }
            )
        }
    }

    private func updateScrollViewMaxHeight(_ desiredContentHeight: CGFloat) {
        scrollViewMaxHeight = Layout.navigationBarHeight
            + desiredContentHeight
            + Layout.doneButtonPadding
            + MainButton.Size.default.height
            + Layout.doneButtonPadding
    }

    private func updateNavigationBarBottomSeparatorVisibility(_ scrollViewMinY: CGFloat) {
        navigationBarBottomSeparatorIsVisible = scrollViewMinY < Layout.navigationBarHeight - Layout.contentTopPadding
    }
}

extension WalletConnectNetworksSelectorView {
    private enum Layout {
        /// 52
        static let navigationBarHeight = WalletConnectNavigationBarView.Layout.topPadding + WalletConnectNavigationBarView.Layout.height
        /// 12
        static let contentTopPadding: CGFloat = 12
        /// 8
        static let contentBottomPadding: CGFloat = 8
        /// 38
        static let sectionHeaderHeight: CGFloat = 38
        /// 52
        static let blockchainRowHeight: CGFloat = 52
        /// 16
        static let doneButtonPadding: CGFloat = 16

        static let scrollViewCoordinateSpace = "WalletConnectNetworksSelectorView.ScrollView"
    }
}
