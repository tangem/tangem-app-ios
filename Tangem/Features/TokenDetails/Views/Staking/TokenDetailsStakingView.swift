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

    @ScaledMetric private var horizontalSpacing: CGFloat = .unit(.x2)
    @ScaledMetric private var verticalSpacing: CGFloat = .unit(.x1)
    @ScaledMetric private var padding: CGFloat = .unit(.x4)
    @ScaledMetric private var borderWidth: CGFloat = .unit(.quarter)

    @ScaledMetric private var iconDimension: CGFloat = .unit(.x10)
    @ScaledMetric private var iconShadowOffsetX: CGFloat = .unit(.x2)

    @ScaledMetric private var skeletonTopWidth: CGFloat = .unit(.x16)
    @ScaledMetric private var skeletonTopHeight: CGFloat = .unit(.x5)
    @ScaledMetric private var skeletonBottomWidth: CGFloat = .unit(.x19)
    @ScaledMetric private var skeletonBottomHeight: CGFloat = .unit(.x4)

    private let cornerRadius: CGFloat = .unit(.x6)
    private let blurRadius: CGFloat = .unit(.x5)
    private let iconShadowBlurRadius: CGFloat = .unit(.x2)

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
        Button(action: item.action) {
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
                        .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
                        .accessibilityIdentifier(TokenAccessibilityIdentifiers.nativeStakingTitle)

                    Text(item.description)
                        .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TangemButton(content: .text(AttributedString(item.actionTitle)), action: item.action)
                    .setStyleType(.accent)
                    .setCornerStyle(.rounded)
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
        Button(action: item.action) {
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
                        .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)
                        .accessibilityIdentifier(TokenAccessibilityIdentifiers.nativeStakingTitle)

                    rewardsStateView(state: item.rewardsState)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: verticalSpacing) {
                    SensitiveText(item.fiatBalance)

                    SensitiveText(item.cryptoBalance)
                        .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
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

    func unavailableView(item: TokenDetailsStakingState.UnavailableItem) -> some View {
        HStack(spacing: horizontalSpacing) {
            Assets.stakingFilledMonochrome.image
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(size: CGSize(bothDimensions: iconDimension))

            VStack(alignment: .leading, spacing: verticalSpacing) {
                Text(item.title)
                    .style(.Tangem.Body16.medium, color: .Tangem.Text.Neutral.tertiary)
                    .accessibilityIdentifier(TokenAccessibilityIdentifiers.nativeStakingTitle)

                Text(item.description)
                    .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
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
    }

    @ViewBuilder
    func rewardsStateView(state: TokenDetailsStakingState.RewardsState) -> some View {
        switch state {
        case .claimed(let text):
            SensitiveText(text)
                .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Status.accent)
        case .empty(let text):
            Text(text)
                .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)
        case .auto: // [REDACTED_TODO_COMMENT]
            EmptyView()
        }
    }

    var loadingView: some View {
        HStack(spacing: horizontalSpacing) {
            skeletonView(width: iconDimension, height: iconDimension)
                .shimmer()

            VStack(alignment: .leading, spacing: verticalSpacing) {
                skeletonView(width: skeletonTopWidth, height: skeletonTopHeight)
                    .shimmer()

                skeletonView(width: skeletonBottomWidth, height: skeletonBottomHeight)
                    .shimmer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .background(Color.Tangem.Surface.level3, in: RoundedRectangle(cornerRadius: .unit(.x6)))
    }

    func skeletonView(width: CGFloat, height: CGFloat) -> some View {
        Capsule(style: .continuous)
            .fill(Color.Tangem.Skeleton.backgroundPrimary)
            .frame(width: width, height: height)
    }
}
