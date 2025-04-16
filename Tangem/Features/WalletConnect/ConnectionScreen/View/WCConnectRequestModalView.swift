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
    
    private let requestDescriptionTransition: AnyTransition = {
        .asymmetric(
            insertion:
                    .move(edge: .bottom)
                    .animation(.default)
                    .combined(with:
                            .opacity.animation(.default.delay(0.05))
                    ),
            removal:
                    .move(edge: .bottom)
                    .animation(.easeOut(duration: 0.5))
                    .combined(with:
                            .opacity.animation(.easeOut(duration: 0.2))
                    )
        )
    }()

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
                MainButton(settings: .init(title: "Connect", action: { viewModel.handleViewAction(.connect) }))
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
                .padding(.horizontal, 16)
                .onTapGesture {
                    viewModel.handleViewAction(.showConnectionDescription)
                }
                .padding(.bottom, 8)

                connectionRequestDescription
            }
            .padding(.vertical, 16)
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
    
    var dappTitle: some View {
        HStack(spacing: 16) {
            if let urlString = viewModel.proposal.proposer.icons.last, let iconURL = URL(string: urlString) {
                IconView(url: iconURL, size: .init(bothDimensions: 56))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.proposal.proposer.name)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(viewModel.proposal.proposer.url)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
            .multilineTextAlignment(.leading)
        }
    }
    
    var connectionRequestHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            Assets.connectNew.image

            Text("Connection request")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipShape(Rectangle())

            Assets.chevronRight.image
                .rotationEffect(Angle(degrees: viewModel.isConnectionRequestDescriptionVisible ? -90 : 0))
                .animation(.easeInOut, value: viewModel.isConnectionRequestDescriptionVisible)
        }
    }
}

// MARK: Connection request details

private extension WCConnectRequestModalView {
    @ViewBuilder
    func connectionRequestRow(type: ActionPermission, text: String) -> some View {
        let foregroundStyle: Color = {
            switch type {
            case .allowed: Colors.Icon.accent.opacity(0.1)
            case .denied: Colors.Icon.warning.opacity(0.1)
            }
        }()
        
        let image: Image = {
            switch type {
            case .allowed: Assets.WalletConnect.miniCheck.image
            case .denied: Assets.cross.image
            }
        }()
        
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .foregroundStyle(foregroundStyle)
                    .frame(size: .init(bothDimensions: 24))
                image
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
        HStack(spacing: 0) {
            Assets.WalletConnect.networkNew.image
                .padding(.trailing, 8)
            Text("Networks")
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
            if let icon = viewModel.tokenIcons.first {
                TokenIcon(tokenIconInfo: icon, size: .init(bothDimensions: 20))
            }
            Assets.WalletConnect.selectIcon.image
        }
    }
}

private enum ActionPermission {
    case allowed
    case denied
}
