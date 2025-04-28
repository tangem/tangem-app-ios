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
    
    @State private var connectingRotationAngle: Angle = .degrees(0)
    @State private var connectionRequestChevronAngle: Angle = .degrees(0)
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.init(top: 12, leading: 16, bottom: 20, trailing: 16))
            
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
        .background(Colors.Background.tertiary)
    }
}

// MARK: - Sections

private extension WCConnectRequestModalView {
    var dappInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                dappTitle
                    .padding(.horizontal, 16)
                
                Divider()
                
                connectionRequestHeader
                    .clipShape(Rectangle())
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        viewModel.handleViewAction(.showConnectionDescription)
                        connectionRequestChevronAngle = .degrees(viewModel.isConnectionRequestDescriptionVisible ? -90 : 0)
                    }
                    .padding(.bottom, 8)
                    .animation(makeDefaultAnimationCurve(duration: 0.4), value: viewModel.isDappInfoLoading)
                
                connectionRequestDescription
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
            
            Divider()
                .padding(.init(top: 10, leading: 46, bottom: 10, trailing: 16))
            
            selectedNetworks
                .padding(.init(top: 0, leading: 16, bottom: 12, trailing: 16))
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
                .overlay(alignment: .trailing) {
                    ZStack {
                        Circle()
                            .foregroundStyle(Colors.Button.secondary)
                            .frame(size: .init(bothDimensions: 28))
                            .onTapGesture { viewModel.handleViewAction(.dismissConnectionView) }
                        Assets.cross.image
                            .renderingMode(.template)
                            .foregroundStyle(Colors.Icon.secondary)
                    }
                }
        }
    }
    
    @ViewBuilder
    var dappTitle: some View {
        if viewModel.isDappInfoLoading {
            dappTitleStub
                .transition(.opacity.animation(makeDefaultAnimationCurve(duration: 0.4)))
        } else {
            HStack(spacing: 16) {
                if let urlString = viewModel.proposal?.proposer.icons.last, let iconURL = URL(string: urlString) {
                    IconView(url: iconURL, size: .init(bothDimensions: 56))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let dappName = viewModel.proposal?.proposer.name, !dappName.isEmpty {
                        Text(viewModel.proposal?.proposer.name ?? "")
                            .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    }
                    
                    if let dappUrl = viewModel.proposal?.proposer.url, !dappUrl.isEmpty {
                        Text(dappUrl)
                            .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    }
                }
                .multilineTextAlignment(.leading)
            }
            .transition(.opacity.animation(makeDefaultAnimationCurve(duration: 0.4)))
        }
    }
    
    @ViewBuilder
    var connectionRequestHeader: some View {
        if case .dappInfoLoading = viewModel.presentationState {
            connectionRequestHeaderStub
        } else {
            HStack(alignment: .center, spacing: 8) {
                Assets.connectNew.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.accent)
                
                Text("Connection request")
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Assets.WalletConnect.chevronRight.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
                    .rotationEffect(connectionRequestChevronAngle)
                    .animation(makeDefaultAnimationCurve(duration: 0.3), value: connectionRequestChevronAngle)
            }
        }
    }
}

// MARK: Connection request details

private extension WCConnectRequestModalView {
    enum ActionPermission {
        case allowed
        case denied
    }
    
    func connectionRequestRow(type: ActionPermission, text: String) -> some View {
        let foregroundStyle: Color = switch type {
        case .allowed: Colors.Icon.accent
        case .denied: Colors.Icon.warning
        }
        
        let image: Image = switch type {
        case .allowed: Assets.WalletConnect.miniCheck.image
        case .denied: Assets.cross.image
        }
        
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .foregroundStyle(foregroundStyle.opacity(0.1))
                    .frame(size: .init(bothDimensions: 24))
                image
                    .renderingMode(.template)
                    .foregroundStyle(foregroundStyle)
            }
            
            Text(text)
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
        }
    }
    
    @ViewBuilder
    var connectionRequestDescription: some View {
        if viewModel.isConnectionRequestDescriptionVisible {
            VStack(alignment: .leading, spacing: 0) {
                Text("Would like to")
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.bottom, 8)
                
                connectionRequestRow(type: .allowed, text: "View your wallet balance and activity")
                    .padding(.bottom, 12)
                
                connectionRequestRow(type: .allowed, text: "Request approval for transactions")
                
                Divider()
                    .padding(.vertical, 12)
                
                Text("Will not be able to")
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.bottom, 8)
                
                connectionRequestRow(type: .denied, text: "Sign transactions without your notice")
            }
            .padding(.horizontal, 16)
            .transition(requestDescriptionTransition)
        }
    }
}

// MARK: - Connection parameters

private extension WCConnectRequestModalView {
    // [REDACTED_TODO_COMMENT]
    var selectedWallet: some View {
        HStack(spacing: 0) {
            Assets.WalletConnect.walletNew.image
                .padding(.trailing, 8)
            Text("Wallet")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
            Text(viewModel.selectedWalletName)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                .padding(.trailing, 2)
            
            Assets.WalletConnect.selectIcon.image
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
            
            if viewModel.presentationState == .content {
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
    
    var connectionRequestHeaderStub: some View {
        HStack(alignment: .center, spacing: 8) {
            Assets.WalletConnect.load.image
                .renderingMode(.template)
                .resizable()
                .frame(size: .init(bothDimensions: 24))
                .foregroundStyle(Colors.Icon.accent)
                .rotationEffect(connectingRotationAngle)
                .animation(connectingAnimationCurve, value: connectingRotationAngle)
                .onAppear {
                    connectingRotationAngle = .degrees(360)
                }
            
            Text("Connecting")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var dappTitleStub: some View {
        HStack(spacing: 16) {
            Rectangle()
                .foregroundStyle(.clear)
                .frame(size: .init(bothDimensions: 56))
                .skeletonable(isShown: true, radius: 12)
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 119, height: 25)
                    .skeletonable(isShown: true, radius: 8)
                
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 168, height: 18)
                    .skeletonable(isShown: true, radius: 8)
            }
        }
    }
}

// MARK: - Helpers

private extension WCConnectRequestModalView {
    var connectingAnimationCurve: Animation {
        .timingCurve(0.45, 0.19, 0.67, 0.86, duration: 1).repeatForever(autoreverses: false)
    }
    
    var requestDescriptionTransition: AnyTransition {
        .asymmetric(
            insertion:
                    .move(edge: .bottom)
                    .animation(.timingCurve(0.76, 0, 0.24, 1, duration: 0.5))
                    .combined(
                        with: .opacity.animation(makeDefaultAnimationCurve(duration: 0.3).delay(0.2))
                    ),
            removal:
                    .move(edge: .bottom)
                    .animation(makeDefaultAnimationCurve(duration: 0.5))
                    .combined(
                        with:.opacity.animation(makeDefaultAnimationCurve(duration: 0.3))
                    )
        )
    }
    
    var connectionRequestChevronAnimation: Animation {
        if viewModel.isConnectionRequestDescriptionVisible {
            .timingCurve(0.76, 0, 0.24, 1, duration: 0.5)
        } else {
            makeDefaultAnimationCurve(duration: 0.3)
        }
    }
    
    func makeDefaultAnimationCurve(duration: TimeInterval) -> Animation {
        .timingCurve(0.65, 0, 0.35, 1, duration: duration)
    }
}
