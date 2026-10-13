//
//  TokenDetailsYieldView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct TokenDetailsYieldView: View {
    let state: TokenDetailsYieldState

    @State private var badge: TokenDetailsYieldState.ActiveBadgeType?
    @State private var spinnerRotation: Double = 0

    @ScaledMetric private var horizontalSpacing: CGFloat = 8
    @ScaledMetric private var verticalSpacing: CGFloat = 4
    @ScaledMetric private var padding: CGFloat = 16
    @ScaledMetric private var borderWidth: CGFloat = 1

    @ScaledMetric private var iconDimension: CGFloat = 40
    @ScaledMetric private var iconShadowOffsetY: CGFloat = 2

    @ScaledMetric private var badgeDimension: CGFloat = 16
    @ScaledMetric private var badgeSpacing: CGFloat = 4

    @ScaledMetric private var spinnerDimension: CGFloat = 12
    @ScaledMetric private var spinnerSpacing: CGFloat = 2

    @ScaledMetric private var promoVerticalSpacing: CGFloat = 12

    @ScaledMetric private var skeletonTopWidth: CGFloat = 64
    @ScaledMetric private var skeletonTopHeight: CGFloat = 20
    @ScaledMetric private var skeletonBottomWidth: CGFloat = 76
    @ScaledMetric private var skeletonBottomHeight: CGFloat = 16

    private let cornerRadius: CGFloat = 24
    private let blurRadius: CGFloat = 20
    private let iconShadowBlurRadius: CGFloat = 16

    var body: some View {
        switch state {
        case .loading:
            loadingView.environment(\.isShimmerActive, true)
        case .available(let item):
            availableView(item: item)
        case .promoAvailable(let item):
            promoAvailableView(item: item)
        case .processing(let item):
            processingView(item: item)
        case .active(let item):
            activeView(item: item)
        case .unavailable:
            EmptyView()
        }
    }
}

// MARK: - Subviews

private extension TokenDetailsYieldView {
    func availableView(item: TokenDetailsYieldState.AvailableItem) -> some View {
        SwiftUI.Button(action: item.action.closure) {
            // [REDACTED_TODO_COMMENT]
            HStack(spacing: horizontalSpacing) {
                shadowedIcon(
                    Assets.YieldModule.yieldFilledEucalyptus.image,
                    color: Color.Tangem.Graphic.Status.positive
                )

                VStack(alignment: .leading, spacing: verticalSpacing) {
                    Text(item.title)
                        .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)

                    Text(item.description)
                        .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Status.positive)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TangemButton(content: .text(AttributedString(item.action.title)), action: item.action.closure)
                    .setStyleType(.positive)
                    .setSize(.x9)
            }
            .padding(padding)
            .background(Color.Tangem.Markers.backgroundTintedGreen, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.Tangem.Graphic.Status.positive.opacity(0.3), lineWidth: cornerRadius)
                    .blur(radius: blurRadius)
                    .blendMode(.lighten)
                    .mask(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.Tangem.Markers.borderTintedGreen, lineWidth: borderWidth)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.availableBlock)
    }

    func promoAvailableView(item: TokenDetailsYieldState.PromoAvailableItem) -> some View {
        VStack(spacing: promoVerticalSpacing) {
            HStack(spacing: horizontalSpacing) {
                shadowedIcon(
                    Assets.YieldModule.yieldFilledEucalyptus.image,
                    color: Color.Tangem.Graphic.Status.positive
                )

                VStack(alignment: .leading, spacing: verticalSpacing) {
                    Text(item.title)

                    Text(item.description)
                        .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Status.positive)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: horizontalSpacing) {
                TangemButton(
                    content: .text(AttributedString(item.learnAction.title)),
                    action: item.learnAction.closure
                )
                .setStyleType(.secondary)
                .setSize(.x9)
                .setHorizontalLayout(.infinity)

                TangemButton(
                    content: .text(AttributedString(item.activateAction.title)),
                    action: item.activateAction.closure
                )
                .setStyleType(.positive)
                .setSize(.x9)
                .setHorizontalLayout(.infinity)
            }
        }
        .padding(padding)
        .background(Color.Tangem.Markers.backgroundTintedGreen, in: RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.Tangem.Graphic.Status.positive.opacity(0.3), lineWidth: cornerRadius)
                .blur(radius: blurRadius)
                .blendMode(.lighten)
                .mask(RoundedRectangle(cornerRadius: cornerRadius))
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.Tangem.Markers.borderTintedGreen, lineWidth: borderWidth)
        }
    }

    func processingView(item: TokenDetailsYieldState.ProcessingItem) -> some View {
        HStack(spacing: horizontalSpacing) {
            processingIcon(type: item.type)

            VStack(alignment: .leading, spacing: verticalSpacing) {
                Text(item.title)
                    .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)

                HStack(spacing: spinnerSpacing) {
                    Text(item.description)
                        .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.tertiary)

                    spinner
                }
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
    func processingIcon(type: TokenDetailsYieldState.ProcessingType) -> some View {
        switch type {
        case .enabling:
            shadowedIcon(
                Assets.YieldModule.yieldFilledTangerine.image,
                color: Color.Tangem.Markers.iconYellow
            )
        case .disabling:
            Assets.YieldModule.yieldFilledTangerine.image
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(size: CGSize(bothDimensions: iconDimension))
        }
    }

    func activeView(item: TokenDetailsYieldState.ActiveItem) -> some View {
        SwiftUI.Button(action: item.action.closure) {
            HStack(spacing: horizontalSpacing) {
                shadowedIcon(
                    Assets.YieldModule.yieldFilledEucalyptus.image,
                    color: Color.Tangem.Graphic.Status.positive
                )

                VStack(alignment: .leading, spacing: verticalSpacing) {
                    HStack(spacing: badgeSpacing) {
                        Text(item.title)
                            .style(Font.Tangem.Body16.medium, color: .Tangem.Text.Neutral.primary)

                        badge.map { badgeView(type: $0) }
                    }

                    Text(item.description)
                        .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Status.positive)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TangemButton(content: .text(AttributedString(item.action.title)), action: item.action.closure)
                    .setStyleType(.secondary)
                    .setSize(.x9)
            }
            .padding(padding)
            .background(Color.Tangem.Surface.level3, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.Tangem.Border.Neutral.primary, lineWidth: borderWidth)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.activeBlock)
        .task {
            badge = await item.badgeType()
        }
    }

    @ViewBuilder
    func badgeView(type: TokenDetailsYieldState.ActiveBadgeType) -> some View {
        switch type {
        case .attention:
            Assets.DesignSystem.attention.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.Tangem.Graphic.Status.attention)
                .frame(size: CGSize(bothDimensions: badgeDimension))
                .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.earnBlockTitleIcon)
        case .warning:
            Assets.DesignSystem.warning.image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.Tangem.Graphic.Neutral.secondary)
                .frame(size: CGSize(bothDimensions: badgeDimension))
                .accessibilityIdentifier(YieldModuleAccessibilityIdentifiers.earnBlockTitleIcon)
        case .none:
            EmptyView()
        }
    }

    func shadowedIcon(_ image: Image, color: Color) -> some View {
        image
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(size: CGSize(bothDimensions: iconDimension))
            .shadow(
                color: color.opacity(0.7),
                radius: iconShadowBlurRadius,
                x: iconShadowOffsetY,
                y: .zero
            )
    }

    var spinner: some View {
        Assets.DesignSystem.load.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.Tangem.Graphic.Neutral.tertiaryConstant)
            .frame(size: CGSize(bothDimensions: spinnerDimension))
            .rotationEffect(.degrees(spinnerRotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    spinnerRotation = 360
                }
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
