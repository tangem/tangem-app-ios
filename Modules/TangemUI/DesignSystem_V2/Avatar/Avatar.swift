//
//  Avatar.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct Avatar: View {
    private let content: Content
    private let size: Size

    @ScaledMetric private var scale: CGFloat = 1
    @Environment(\.isShimmerActive) private var isShimmerActive

    public init(_ content: Content, size: Size = .size40) {
        self.content = content
        self.size = size
    }

    public var body: some View {
        shape(size.metrics.scaled(by: DecorationScale.clamped(scale)))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func shape(_ metrics: Metrics) -> some View {
        let radius = content.isAccount ? metrics.accountCornerRadius : metrics.side / 2

        if isShimmerActive {
            Shimmer()
                .variant(.custom(cornerRadius: radius))
                .frame(width: metrics.side, height: metrics.side)
        } else {
            fill
                .overlay { glyph(metrics) }
                .overlay { highlight }
                .frame(width: metrics.side, height: metrics.side)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }

    @ViewBuilder
    private var fill: some View {
        switch content {
        case .icon(_, let appearance):
            appearance.background
        case .transaction(_, let status):
            status.background
        case .user(.initial(_, let fill)), .account(_, let fill):
            fill
        case .user(.fallback):
            DesignSystem.Color.bgTransparentPrimary
        case .address(.some(let image)), .asset(let image):
            image.resizable().scaledToFill()
        case .address(.none):
            DesignSystem.Color.bgTransparentPrimary
        }
    }

    @ViewBuilder
    private func glyph(_ metrics: Metrics) -> some View {
        switch content {
        case .icon(let image, let appearance):
            tinted(image, color: appearance.tint, side: metrics.glyph)
        case .transaction(let kind, let status):
            tinted(kind.icon(for: size), color: status.tint, side: metrics.glyph)
        case .user(.initial(let initial, _)):
            Text(initial)
                .style(size.initialFont, color: DesignSystem.Color.textStaticDarkPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        case .user(.fallback):
            tinted(size.fallbackGlyph, color: DesignSystem.Color.iconSecondary, side: metrics.glyph)
        case .account(let image, _):
            tinted(image, color: DesignSystem.Color.iconStaticDark, side: metrics.side / 2)
        case .address, .asset:
            EmptyView()
        }
    }

    @ViewBuilder
    private var highlight: some View {
        if content.hasHighlight {
            LinearGradient(
                colors: [DesignSystem.Color.paletteBaseWhite.opacity(0), DesignSystem.Color.paletteBaseWhite.opacity(Metrics.highlightOpacity)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func tinted(_ icon: ImageType, color: Color, side: CGFloat) -> some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: side, height: side)
            .foregroundStyle(color)
    }
}
