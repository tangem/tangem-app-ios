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
        let radius = content.shape == .roundedSquare ? metrics.cornerRadius : metrics.side / 2

        if isShimmerActive {
            Shimmer()
                .variant(.custom(cornerRadius: radius))
                .frame(width: metrics.side, height: metrics.side)
        } else if content.hasIndicator, let indicator = metrics.indicator {
            clipped(metrics, radius: radius)
                .cutOutMask {
                    CutOutHole(diameter: indicator.cutOutDiameter)
                        .padding(.trailing, -indicator.cutOutOverhang)
                        .padding(.bottom, -indicator.cutOutOverhang)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
                .overlay(alignment: .bottomTrailing) {
                    pendingIndicator(indicator)
                        .padding(.trailing, -indicator.overhang)
                        .padding(.bottom, -indicator.overhang)
                }
        } else {
            clipped(metrics, radius: radius)
        }
    }

    private func clipped(_ metrics: Metrics, radius: CGFloat) -> some View {
        fill
            .overlay { glyph(metrics) }
            .frame(width: metrics.side, height: metrics.side)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    @ViewBuilder
    private var fill: some View {
        switch content {
        case .icon(_, let appearance, _):
            appearance.background
        case .transaction(_, let status):
            status.background
        case .user(.initial(_, let fill)):
            fill
        case .account(let account, _):
            account.fill
        case .user(.fallback), .address(.none):
            DesignSystem.Color.bgTransparentPrimary
        case .address(.some(let image)):
            image.resizable().scaledToFill()
        case .asset(let image, _):
            image.resizable().scaledToFill()
        }
    }

    @ViewBuilder
    private func glyph(_ metrics: Metrics) -> some View {
        switch content {
        case .icon(let image, let appearance, _):
            tinted(image, color: appearance.tint, side: metrics.glyph)
        case .transaction(let kind, let status):
            tinted(kind.icon(for: size), color: status.tint, side: metrics.glyph)
        case .user(.initial(let initial, _)):
            letter(initial)
        case .user(.fallback):
            tinted(size.fallbackGlyph, color: DesignSystem.Color.iconSecondary, side: metrics.glyph)
        case .account(.icon(let image, _), _):
            tinted(image, color: Self.accountGlyphTint, side: metrics.side)
        case .account(.letter(let initial, _), _):
            letter(initial)
        case .account(.prediction, _):
            tinted(DesignSystem.Icons.accountPredictions, color: DesignSystem.Color.iconStaticDark, side: metrics.side)
        case .account(.gacha, _):
            tinted(DesignSystem.Icons.accountGacha, color: DesignSystem.Color.iconStaticDark, side: metrics.side)
        case .account(.visa, _):
            tinted(DesignSystem.Icons.accountVisa, color: Self.accountGlyphTint, side: metrics.side)
        case .account(.money, _):
            tinted(DesignSystem.Icons.accountSafe, color: Self.accountGlyphTint, side: metrics.side)
        case .address, .asset:
            EmptyView()
        }
    }

    private func letter(_ text: String) -> some View {
        Text(text)
            .style(size.initialFont, color: DesignSystem.Color.textStaticDarkPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private func pendingIndicator(_ indicator: Indicator) -> some View {
        DesignSystem.Color.bgAccentYellow
            .overlay {
                tinted(DesignSystem.Icons.ClockHands.regular12, color: DesignSystem.Color.iconStaticDark, side: indicator.side)
            }
            .frame(width: indicator.side, height: indicator.side)
            .clipShape(Circle())
    }

    private static let accountGlyphTint = DesignSystem.Color.iconStaticDark.opacity(0.8)

    private func tinted(_ icon: ImageType, color: Color, side: CGFloat) -> some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: side, height: side)
            .foregroundStyle(color)
    }
}
