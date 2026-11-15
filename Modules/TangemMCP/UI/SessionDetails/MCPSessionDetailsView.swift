//
//  MCPSessionDetailsView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils

struct MCPSessionDetailsView: View {
    @ObservedObject var viewModel: MCPSessionDetailsViewModel
    let imageCache: Kingfisher.ImageCache

    var body: some View {
        VStack(spacing: .zero) {
            header

            VStack(spacing: 20) {
                agentAndUserWalletCard
                revokeButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .animation(Animation.mcpFloatingSheetFrameUpdate, value: viewModel.state)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackground = FloatingSheetConfiguration.Background.mcpFloatingSheet
            configuration.backgroundInteractionBehavior = FloatingSheetConfiguration.BackgroundInteractionBehavior.tapToDismiss
            configuration.verticalSwipeBehavior = FloatingSheetConfiguration.VerticalSwipeBehavior(
                target: .backgroundAndSheet,
                threshold: 100
            )
        }
    }

    private var header: some View {
        FloatingSheetNavigationBarView(
            title: viewModel.state.title,
            subtitle: viewModel.state.connectionDate,
            backgroundColor: DesignSystem.Color.bgPrimary,
            bottomSeparatorLineIsVisible: false,
            closeButtonAction: { viewModel.handle(action: .closeButtonTapped) }
        )
    }

    private var agentAndUserWalletCard: some View {
        VStack(spacing: .zero) {
            Row(title: viewModel.state.agent.name, subtitle: viewModel.state.agent.host)
                .start {
                    MCPAgentIconView(iconURL: viewModel.state.agent.iconURL, imageCache: imageCache)
                }
                .showDivider()

            userWalletRow
        }
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(.rect(cornerRadius: 24))
    }

    private var userWalletRow: some View {
        Row(title: viewModel.state.userWallet.title)
            .valueAccessory {
                HStack(spacing: 4) {
                    if let thumbnail = viewModel.state.userWallet.thumbnail {
                        MiniatureWalletView(type: thumbnail)
                            .frame(width: 20, height: 20)
                    }

                    Text(viewModel.state.userWallet.name)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                }
            }
    }

    private var revokeButton: some View {
        TangemUI.Button(
            label: viewModel.state.revokeButton.title,
            accessibilityLabel: nil,
            action: { viewModel.handle(action: .revokeButtonTapped) }
        )
        .loading(.spinner(if: viewModel.state.revokeButton.isLoading))
        .styleType(.secondary(.default))
        .size(.x12)
        .horizontalLayout(.infinity)
    }
}
