//
//  MCPSendIntentView.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI

struct MCPSendIntentProposalView: View {
    let viewModel: MCPIntentProposalViewModel<MCPSendIntentProposalState>
    let kingfisherImageCache: ImageCache

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var appearAnimationHasPlayed = false

    var body: some View {
        VStack(spacing: 16) {
            tokenIconView(viewModel.state.tokenIcon)
                .offset(x: appearAnimationHasPlayed ? 0 : 28)
                .animation(appearAnimation, value: appearAnimationHasPlayed)

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
