//
//  TokenDetailsStakingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct TokenDetailsStakingView: View {
    let state: TokenDetailsStakingState

    @ScaledMetric private var horizontalSpacing: CGFloat = 8
    @ScaledMetric private var verticalSpacing: CGFloat = 4
    @ScaledMetric private var padding: CGFloat = 16
    @ScaledMetric private var borderWidth: CGFloat = 1

    @ScaledMetric private var iconDimension: CGFloat = 40
    @ScaledMetric private var iconShadowOffsetX: CGFloat = 8

    @ScaledMetric private var skeletonTopWidth: CGFloat = 64
    @ScaledMetric private var skeletonTopHeight: CGFloat = 20
    @ScaledMetric private var skeletonBottomWidth: CGFloat = 76
    @ScaledMetric private var skeletonBottomHeight: CGFloat = 16

    private let cornerRadius: CGFloat = 24
    private let blurRadius: CGFloat = 20
    private let iconShadowBlurRadius: CGFloat = 8

    var body: some View {
        switch state {
        case .loading:
            loadingView.environment(\.isShimmerActive, true)
        case .available(let item):
            availableView(item: item)
        case .enable(let item):
            enableView(item: item)
        case .unavailable(let item):
            unavailableView(item: item)
        }
    }
}

// MARK: - Subviews

private extension TokenDetailsStakingView {
    func availableView(item: TokenDetailsStakingState.AvailableItem) -> some View {
        SwiftUI.Button(action: item.action) {
            // [REDACTED_TODO_COMMENT]
            HStack(spacing: horizontalSpacing) {
                Assets.stakingFilledAero.image
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(size: CGSize(bothDimensions: iconDimension))
                    .shadow(
                        color: Color.Tangem.Fill.Status.accent.opacity(0.35),
                        radius: iconShadowBlurRadius,
                        x: .zero,
                        y: iconShadowOffsetX
                    )

                VStack(alignment: .leading, spacing: verticalSpacing) {
                    Text(item.title)
                        .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
                        .accessibilityIdentifier(TokenAccessibilityIdentifiers.nativeStakingTitle)

                    Text(item.description)
                        .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TangemButton(content: .text(AttributedString(item.actionTitle)), action: item.action)
                    .setStyleType(.accent)
                    .setSize(.x9)
            }
            .padding(padding)
            .background(Color.Tangem.Markers.backgroundTintedBlue, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.Tangem.Fill.Status.accent.opacity(0.3), lineWidth: cornerRadius)
                    .blur(radius: blurRadius)
                    .blendMode(.lighten)
                    .mask(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.Tangem.Markers.borderTintedBlue, lineWidth: borderWidth)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.nativeStakingBlock)
    }

    func enableView(item: TokenDetailsStakingState.EnableItem) -> some View {
        SwiftUI.Button(action: item.action) {
            HStack(spacing: horizontalSpacing) {
                Assets.stakingFilledAero.image
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(size: CGSize(bothDimensions: iconDimension))
                    .shadow(
                        color: Color.Tangem.Fill.Status.accent.opacity(0.35),
                        radius: iconShadowBlurRadius,
                        x: .zero,
                        y: iconShadowOffsetX
                    )

                VStack(alignment: .leading, spacing: verticalSpacing) {
                    Text(item.title)
                        .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
                        .accessibilityIdentifier(TokenAccessibilityIdentifiers.nativeStakingTitle)

                    rewardsStateView(state: item.rewardsState)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: verticalSpacing) {
                    SensitiveText(item.fiatBalance)

                    SensitiveText(item.cryptoBalance)
                        .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                }
                .accessibilityIdentifier(TokenAccessibilityIdentifiers.stakingBalance)
            }
            .padding(padding)
            .background(Color.Tangem.Surface.level3, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.Tangem.Border.Neutral.primary, lineWidth: borderWidth)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.nativeStakingBlock)
    }

    @ViewBuilder
    func unavailableView(item: TokenDetailsStakingState.UnavailableItem) -> some View {
        let titleColor: Color = item.action == nil ? .Tangem.Text.Neutral.tertiary : .Tangem.Text.Neutral.primary

        let content = HStack(spacing: horizontalSpacing) {
            Assets.stakingFilledMonochrome.image
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(size: CGSize(bothDimensions: iconDimension))

            VStack(alignment: .leading, spacing: verticalSpacing) {
                Text(item.title)
                    .style(Font.Tangem.Body16.medium, color: titleColor)
                    .accessibilityIdentifier(TokenAccessibilityIdentifiers.nativeStakingTitle)

                Text(item.description)
                    .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(padding)
        .background(Color.Tangem.Surface.level3, in: RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.Tangem.Border.Neutral.primary, lineWidth: borderWidth)
        }

        if let action = item.action {
            SwiftUI.Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityIdentifier(TokenAccessibilityIdentifiers.nativeStakingBlock)
        } else {
            content
                .accessibilityIdentifier(TokenAccessibilityIdentifiers.nativeStakingBlock)
        }
    }

    @ViewBuilder
    func rewardsStateView(state: TokenDetailsStakingState.RewardsState) -> some View {
        switch state {
        case .claimed(let text):
            SensitiveText(text)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Status.accent)
        case .empty(let text):
            Text(text)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
        case .auto(let text):
            Text(text)
                .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Status.accent)
        }
    }

    var loadingView: some View {
        HStack(spacing: horizontalSpacing) {
            Shimmer().variant(.custom(width: iconDimension, height: iconDimension))

            VStack(alignment: .leading, spacing: verticalSpacing) {
                Shimmer().variant(.custom(width: skeletonTopWidth, height: skeletonTopHeight))

                Shimmer().variant(.custom(width: skeletonBottomWidth, height: skeletonBottomHeight))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .background(Color.Tangem.Surface.level3, in: RoundedRectangle(cornerRadius: 24))
    }
}
