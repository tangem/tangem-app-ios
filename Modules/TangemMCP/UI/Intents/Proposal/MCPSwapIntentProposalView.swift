//
//  MCPSwapIntentProposalView.swift
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

struct MCPSwapIntentProposalView: View {
    let viewModel: MCPIntentProposalViewModel<MCPSwapIntentProposalState>
    let kingfisherImageCache: ImageCache

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var appearAnimationHasPlayed = false

    var body: some View {
        VStack(spacing: 16) {
            icons

            MCPIntentTitleView(title: viewModel.state.title)

            MCPIntentProposalDescriptionSectionView(
                section: viewModel.state.intentDescription,
                kingfisherImageCache: kingfisherImageCache
            )

            proceedButton
        }
        .onAppear {
            appearAnimationHasPlayed = true
        }
    }

    private var icons: some View {
        HStack(spacing: 8) {
            tokenIconView(viewModel.state.fromTokenIcon)
                .offset(x: appearAnimationHasPlayed ? 0 : 28)
                .zIndex(2)

            DesignSystem.Icons.ArrowRight.regular20.image
                .resizable()
                .scaledToFill()
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(width: 20, height: 20)
                .opacity(appearAnimationHasPlayed ? 1 : 0)
                .zIndex(1)

            tokenIconView(viewModel.state.toTokenIcon)
                .offset(x: appearAnimationHasPlayed ? 0 : -20)
                .zIndex(0)
        }
        .animation(appearAnimation, value: appearAnimationHasPlayed)
    }

    private func tokenIconView(_ state: MCPTokenIconState) -> some View {
        TokenIconV2(
            tokenIconInfo: TokenIconInfo(
                name: state.accessibilityIdentifier,
                blockchainIconAsset: state.networkIconAsset,
                imageURL: state.iconURL,
                isCustom: state.isCustom,
                customTokenColor: nil
            ),
            size: .size56
        )
        .animation(nil, value: appearAnimationHasPlayed)
        .geometryGroupBackport()
    }

    private var appearAnimation: Animation? {
        accessibilityReduceMotion ? nil : Animation.tokenIconAppear
    }

    private var proceedButton: some View {
        TangemUI.Button(label: viewModel.state.proceedButtonTitle, accessibilityLabel: nil) {
            viewModel.handle(action: .proceedButtonTapped)
        }
        .styleType(.primary)
        .size(.x12)
        .horizontalLayout(.infinity)
        .padding(.top, 8)
    }
}
