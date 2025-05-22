//
//  WCConnectRequestModalView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

struct WCConnectRequestModalView: View {
    @ObservedObject var viewModel: WCConnectionSheetViewModel

    var body: some View {
        content
            .background {
                Colors.Background.tertiary
            }
    }

    private var content: some View {
        ZStack {
            if case .walletSelector(let input) = viewModel.presentationState {
                WCWalletSelectorView(input: input)
                    .transition(walletSelectorTransition)
            }

            if case .networkSelector(let input) = viewModel.presentationState {
                WCNetworksSelectorView(input: input)
                    .transition(connectionDetailsTransition)
            }

            if viewModel.isConnectionDetailsPresented {
                connectionDetails
                    .transition(viewModel.isTransitionFromNetworkSelector ? walletSelectorTransition : connectionDetailsTransition)
            }
        }
    }

    private var connectionDetails: some View {
        VStack(spacing: 12) {
            header

            scrollableSections
        }
        .overlay(alignment: .bottom, content: actionButtons)
    }

    private var scrollableSections: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                dappInfoSection
                    .padding(.init(top: 0, leading: 16, bottom: 14, trailing: 16))

                connectionParametersSection
                    .padding(.init(top: 0, leading: 16, bottom: Constants.scrollContentBottomPadding, trailing: 16))
            }
            .readGeometry(\.size.height) { updatedHeight in
                withAnimation(scrollContentHeighAnimation(updatedHeight)) {
                    viewModel.contentHeight = updatedHeight
                }
            }
        }
        .frame(maxHeight: viewModel.contentHeight, alignment: .top)
        .scrollDisabledBackport(viewModel.contentHeight < viewModel.containerHeight)
        .readGeometry(\.size.height) { updatedHeight in
            viewModel.containerHeight = updatedHeight
        }
    }

    private func actionButtons() -> some View {
        HStack(spacing: 8) {
            MainButton(settings: .init(title: "Cancel", style: .secondary, action: { viewModel.handleViewAction(.cancel) }))
            MainButton(
                settings: .init(
                    title: "Connect",
                    isLoading: viewModel.isConnecting,
                    isDisabled: viewModel.isConnectionButtonDisabled,
                    action: { viewModel.handleViewAction(.connect) }
                )
            )
        }
        .padding(.init(top: 0, leading: 16, bottom: 16, trailing: 16))
        .background(
            ListFooterOverlayShadowView()
                .padding(.top, -50)
        )
    }
}

// MARK: - Sections

private extension WCConnectRequestModalView {
    var dappInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                WCDappTitleView(isLoading: viewModel.isDappInfoLoading, proposal: viewModel.proposal)
                    .padding(.horizontal, 16)

                Separator(height: .minimal, color: Colors.Stroke.primary)
                    .padding(.vertical, 12)

                WCConnectionRequestDescriptionView(isLoading: viewModel.isDappInfoLoading)
            }
            .padding(.init(top: 16, leading: 0, bottom: 12, trailing: 0))
        }
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }

    var connectionParametersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            selectedWallet
                .padding(.init(top: 12, leading: 16, bottom: 0, trailing: 16))
                .disabled(viewModel.isDappInfoLoading)

            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.init(top: 10, leading: 46, bottom: 10, trailing: 16))

            selectedNetworks
                .padding(.init(top: 0, leading: 16, bottom: 12, trailing: 16))
                .disabled(viewModel.isDappInfoLoading)

            if viewModel.presentationState == .noRequiredChains {
                Separator(height: .minimal, color: Colors.Stroke.primary)

                WCRequiredNetworksView(blockchainNames: viewModel.requiredBlockchainNames)
                    .padding(.init(top: 14, leading: 16, bottom: 14, trailing: 16))
            }
        }
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }
}

// MARK: - Header

private extension WCConnectRequestModalView {
    var header: some View {
        WalletConnectNavigationBarView(
            title: "Wallet Connect",
            closeButtonAction: { viewModel.handleViewAction(.dismissConnectionView) }
        )
    }
}

// MARK: - Connection parameters

private extension WCConnectRequestModalView {
    var selectedWallet: some View {
        HStack(spacing: 0) {
            Assets.Glyphs.walletNew.image
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Colors.Icon.accent)
                .padding(.trailing, 8)
            Text("Wallet")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
            Text(viewModel.selectedWalletName)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                .padding(.trailing, 2)

            if viewModel.isOtherWalletSelectorVisible {
                Assets.Glyphs.selectIcon.image
            }
        }
        .onTapGesture {
            viewModel.handleViewAction(.showUserWallets)
        }
    }

    var selectedNetworks: some View {
        return HStack(spacing: 0) {
            Assets.Glyphs.networkNew.image
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(Colors.Icon.accent)
                .padding(.trailing, 8)

            Text("Networks")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)

            tokenSelectionIcon

            networkSelectionIcon
        }
        .clipShape(Rectangle())
        .onTapGesture {
            viewModel.handleViewAction(.showUserNetworks)
        }
    }

    @ViewBuilder
    var tokenSelectionIcon: some View {
        if viewModel.isDappInfoLoading {
            connectionNetworksStub
        } else if viewModel.isNetworksPreviewPresented {
            WCConnectionNetworksView(tokenIconsInfo: viewModel.tokenIconsInfo)
                .transition(.opacity.animation(makeDefaultAnimationCurve(duration: 0.4)))
        }
    }

    @ViewBuilder
    var networkSelectionIcon: some View {
        if viewModel.isNetworksPreviewPresented {
            Assets.Glyphs.selectIcon.image
                .transition(.opacity.animation(makeDefaultAnimationCurve(duration: 0.3)))
        } else if viewModel.presentationState == .noRequiredChains {
            Assets.Glyphs.chevronRightNew.image
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.informative)
                .transition(.opacity.animation(makeDefaultAnimationCurve(duration: 0.3)))
        }
    }
}

// MARK: Stub views

private extension WCConnectRequestModalView {
    var connectionNetworksStub: some View {
        Rectangle()
            .foregroundStyle(.clear)
            .frame(width: 94, height: 24)
            .skeletonable(isShown: true, radius: 8)
            .transition(.opacity.animation(makeDefaultAnimationCurve(duration: 0.4)))
    }
}

// MARK: - UI Helpers

private extension WCConnectRequestModalView {
    var mainContentOpacityTransition: AnyTransition {
        .opacity.animation(.timingCurve(0.69, 0.07, 0.27, 0.95, duration: 0.3))
    }

    var mainContentOpacityTransitionWithDelay: AnyTransition {
        .opacity.animation(.timingCurve(0.69, 0.07, 0.27, 0.95, duration: 0.3).delay(0.2))
    }

    var walletSelectorTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: mainContentOpacityTransitionWithDelay),
            removal: .move(edge: .top).combined(with: mainContentOpacityTransition)
        )
    }

    var connectionDetailsTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: mainContentOpacityTransitionWithDelay),
            removal: .move(edge: .bottom).combined(with: mainContentOpacityTransition)
        )
    }

    var walletSelectorContnetTransition: AnyTransition {
        let animationCurve: Animation = .timingCurve(0.69, 0.07, 0.27, 0.95, duration: 0.5)

        return .move(edge: .bottom).animation(animationCurve).combined(with: .opacity.animation(animationCurve))
    }

    func scrollContentHeighAnimation(_ updatedHeight: CGFloat) -> Animation {
        if updatedHeight > viewModel.contentHeight {
            .timingCurve(0.76, 0, 0.24, 1, duration: 0.5)
        } else {
            makeDefaultAnimationCurve(duration: 0.3)
        }
    }

    func makeDefaultAnimationCurve(duration: TimeInterval) -> Animation {
        .timingCurve(0.65, 0, 0.35, 1, duration: duration)
    }
}

// MARK: - Constants

private enum Constants {
    static var scrollContentBottomPadding: CGFloat { MainButton.Size.default.height + 40 } // summ padding between scroll content and overlay buttons
}
