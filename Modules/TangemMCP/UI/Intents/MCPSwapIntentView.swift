//
//  MCPSwapIntentView.swift
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

struct MCPSwapIntentView: View {
    let viewModel: MCPSwapIntentViewModel
    let kingfisherImageCache: ImageCache

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var tokensAppearAnimationHasPlayed = false

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                backgroundColor: DesignSystem.Color.bgPrimary,
                closeButtonAction: { viewModel.handle(action: .closeButtonTapped) }
            )

            VStack(spacing: 16) {
                icons

                MCPIntentTitleView(title: viewModel.state.title)

                MCPIntentDescriptionSectionView(section: viewModel.state.intentDescription, kingfisherImageCache: kingfisherImageCache)

                MCPIntentPrimaryButton(title: viewModel.state.proceedButtonTitle) {
                    viewModel.handle(action: .primaryButtonTapped)
                }
            }
            .padding([.horizontal, .bottom], 16)
        }
        .onAppear {
            tokensAppearAnimationHasPlayed = true
        }
        .mcpIntentSheetConfiguration()
    }

    private var icons: some View {
        HStack(spacing: 8) {
            MCPIntentTokenIconView(state: viewModel.state.fromTokenIcon, hasAppeared: tokensAppearAnimationHasPlayed)
                .offset(x: tokensAppearAnimationHasPlayed ? 0 : 28)
                .zIndex(2)

            DesignSystem.Icons.ArrowRight.regular20.image
                .resizable()
                .scaledToFill()
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(size: .init(bothDimensions: 20))
                .opacity(tokensAppearAnimationHasPlayed ? 1 : 0)
                .zIndex(1)

            MCPIntentTokenIconView(state: viewModel.state.toTokenIcon, hasAppeared: tokensAppearAnimationHasPlayed)
                .offset(x: tokensAppearAnimationHasPlayed ? 0 : -20)
                .zIndex(0)
        }
        .animation(.mcpIntentIconsAppear(reduceMotion: accessibilityReduceMotion), value: tokensAppearAnimationHasPlayed)
    }
}
