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
            navigationBar

            VStack(spacing: 16) {
                icons
                title
                intentDescriptionSection
                proceedButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onAppear {
            tokensAppearAnimationHasPlayed = true
        }
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .consumeTouches
            configuration.sheetBackground = .color(DesignSystem.Color.bgPrimary)
        }
    }

    private var navigationBar: some View {
        FloatingSheetNavigationBarView(
            backgroundColor: DesignSystem.Color.bgPrimary,
            closeButtonAction: { viewModel.handle(action: .closeButtonTapped) }
        )
    }

    private var icons: some View {
        HStack(spacing: 8) {
            tokenIconView(viewModel.state.fromTokenIcon)
                .offset(x: leadingTokenIconOffsetX)
                .zIndex(2)

            DesignSystem.Icons.ArrowRight.regular20.image
                .resizable()
                .scaledToFill()
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .frame(width: 20, height: 20)
                .opacity(arrowIconAssetOpacity)
                .zIndex(1)

            tokenIconView(viewModel.state.toTokenIcon)
                .offset(x: trailingTokenIconOffsetX)
                .zIndex(0)
        }
        .animation(tokensOffsetAnimation, value: tokensAppearAnimationHasPlayed)
    }

    private func tokenIconView(_ tokenIconState: MCPSwapIntentState.TokenIconState) -> some View {
        TokenIconV2(
            tokenIconInfo: TokenIconInfo(
                name: tokenIconState.accessibilityIdentifier,
                blockchainIconAsset: tokenIconState.localIconAsset,
                imageURL: tokenIconState.remoteIconURL,
                isCustom: tokenIconState.isCustom,
                customTokenColor: nil
            ),
            size: .size56
        )
        .animation(nil, value: tokensAppearAnimationHasPlayed)
        .geometryGroupBackport()
    }

    private var title: some View {
        Text(viewModel.state.title)
            .font(token: DesignSystem.Font.headingSmallToken)
            .foregroundStyle(DesignSystem.Color.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
    }

    private var intentDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                agentIcon

                Text(viewModel.state.intentDescription.agent.host)
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)

                Spacer(minLength: .zero)
            }

            Text(viewModel.state.intentDescription.body)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(DesignSystem.Color.textPrimary)
        }
        .padding(16)
        .background(DesignSystem.Color.bgTransparentOnMaterialPrimary)
        .clipShape(.rect(cornerRadius: 24))
    }

    private var agentIcon: some View {
        KFImage(viewModel.state.intentDescription.agent.iconURL)
            .placeholder {
                Shimmer()
            }
            .onFailureView {
                DesignSystem.Icons.Server.filled12.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(DesignSystem.Color.iconBrand)
                    .frame(width: 16, height: 16)
                    .background(DesignSystem.Color.bgStatusInfoSubtle)
            }
            .targetCache(kingfisherImageCache)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .clipShape(.rect(cornerRadius: 4))
    }

    private var proceedButton: some View {
        TangemUI.Button(
            label: viewModel.state.proceedButtonTitle,
            accessibilityLabel: nil,
            action: {
                viewModel.handle(action: .proceedButtonTapped)
            }
        )
        .styleType(.primary)
        .size(.x12)
        .horizontalLayout(.infinity)
        .padding(.top, 8)
    }

    private var leadingTokenIconOffsetX: CGFloat {
        tokensAppearAnimationHasPlayed ? 0 : 28
    }

    private var trailingTokenIconOffsetX: CGFloat {
        tokensAppearAnimationHasPlayed ? 0 : -20
    }

    private var arrowIconAssetOpacity: CGFloat {
        tokensAppearAnimationHasPlayed ? 1 : 0
    }

    private var tokensOffsetAnimation: Animation? {
        accessibilityReduceMotion
            ? nil
            : Animation.timingCurve(0.42, 0, 0.58, 1, duration: 0.2).delay(0.55)
    }
}
