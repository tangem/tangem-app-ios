//
//  WCConnectRequestModalView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct WCConnectRequestModalView: View {
    @ObservedObject var viewModel: WCConnectionSheetViewModel

    var body: some View {
        content
    }

    private var content: some View {
        ZStack {
            if case .walletSelector = viewModel.presentationState {
                walletSelector
                    .transition(walletSelectorTransition)
            } else {
                connectionDetails
                    .transition(connectionDetailsTransition)
            }
        }
        .background {
            // [REDACTED_TODO_COMMENT]
            Colors.Background.tertiary
        }
    }

    private var connectionDetails: some View {
        VStack(spacing: 0) {
            header
                .padding(.init(top: 20, leading: 16, bottom: 24, trailing: 16))

            dappInfoSection
                .padding(.init(top: 0, leading: 16, bottom: 14, trailing: 16))

            connectionParametersSection
                .padding(.init(top: 0, leading: 16, bottom: 24, trailing: 16))

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
        }
    }

    private var walletSelector: some View {
        WCWalletSelectorView(
            selectedWalletId: viewModel.selectedUserWalletId,
            userWalletModels: viewModel.userWalletModels,
            onTapAction: { viewModel.handleViewAction(.selectUserWallet($0)) },
            backAction: { viewModel.handleViewAction(.returnToConnectionDetails) }
        )
        .padding(.init(top: 20, leading: 16, bottom: 14, trailing: 16))
    }
}

// MARK: - Sections

private extension WCConnectRequestModalView {
    var dappInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                WCDappTitleView(isLoading: viewModel.isDappInfoLoading, proposal: viewModel.proposal)
                    .padding(.horizontal, 16)

                Divider()
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

            Divider()
                .padding(.init(top: 10, leading: 46, bottom: 10, trailing: 16))

            selectedNetworks
                .padding(.init(top: 0, leading: 16, bottom: 12, trailing: 16))
                .disabled(viewModel.isDappInfoLoading)
        }
        .background(Colors.Background.action)
        .cornerRadius(14, corners: .allCorners)
    }
}

// MARK: - Subviews

private extension WCConnectRequestModalView {
    var header: some View {
        HStack(alignment: .center) {
            Text("Wallet Connect")
                .style(Fonts.Bold.headline, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing, content: closeButton)
        }
    }

    private func closeButton() -> some View {
        Button(
            action: { viewModel.handleViewAction(.dismissConnectionView) },
            label: {
                ZStack {
                    Circle()
                        .foregroundStyle(Colors.Button.secondary)
                        .frame(size: .init(bothDimensions: 28))
                    Assets.cross.image
                        .renderingMode(.template)
                        .foregroundStyle(Colors.Icon.secondary)
                        .rotationEffect(.degrees(180))
                }
            }
        )
    }
}

// MARK: - Connection parameters

private extension WCConnectRequestModalView {
    var selectedWallet: some View {
        HStack(spacing: 0) {
            Assets.WalletConnect.walletNew.image
                .renderingMode(.template)
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
                Assets.WalletConnect.selectIcon.image
            }
        }
        .onTapGesture {
            viewModel.handleViewAction(.showUserWallets)
        }
    }

    var selectedNetworks: some View {
        // [REDACTED_TODO_COMMENT]
        return HStack(spacing: 0) {
            Assets.WalletConnect.networkNew.image
                .padding(.trailing, 8)
            Text("Networks")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)

            ZStack(alignment: .trailing) {
                if viewModel.isDappInfoLoading {
                    connectionNetworksStub
                } else {
                    WCConnectionNetworksView(tokenIconsInfo: viewModel.makeTokenIconsInfo())
                        .transition(.opacity.animation(makeDefaultAnimationCurve(duration: 0.4)))
                }
            }

            if viewModel.presentationState == .connectionDetails {
                Assets.WalletConnect.selectIcon.image
                    .transition(.opacity.animation(makeDefaultAnimationCurve(duration: 0.3)))
            }
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

    func makeDefaultAnimationCurve(duration: TimeInterval) -> Animation {
        .timingCurve(0.65, 0, 0.35, 1, duration: duration)
    }
}
