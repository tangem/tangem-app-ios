//
//  TangemShimmer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

/// A skeleton placeholder block with a moving shine. Use ``variant(_:)`` to pick a text-shaped
/// or custom-sized block; the default fills its parent's frame.
///
/// ```swift
/// TangemShimmer()
/// TangemShimmer().variant(.text(style: .body))               // bar fills the style's default share of the parent
/// TangemShimmer().variant(.custom(width: 100, height: 24))
/// ```
public struct TangemShimmer: View {
    private var variant: Variant = .custom()

    public init() {}

    public var body: some View {
        switch variant {
        case .text(let style):
            TangemShimmerTextBlock(style: style)

        case .custom(let width, let height, let cornerRadius):
            TangemShimmerCustomBlock(width: width, height: height, cornerRadius: cornerRadius)
        }
    }
}

// MARK: - Setupable

extension TangemShimmer: Setupable {
    public func variant(_ variant: Variant) -> Self {
        map { $0.variant = variant }
    }
}

// MARK: - Variant

public extension TangemShimmer {
    enum Variant: Hashable, Sendable {
        case text(style: TextStyle)
        case custom(width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat? = nil)
    }

    enum TextStyle: Hashable, Sendable, CaseIterable {
        case display
        case headingMedium
        case headingSmall
        case body
        case subheading
        case caption

        var lineHeight: CGFloat {
            switch self {
            case .display:
                Font.Display.medium.lineHeight

            case .headingMedium:
                Font.Heading.medium.lineHeight

            case .headingSmall:
                Font.Heading.small.lineHeight

            case .body:
                Font.Body.medium.lineHeight

            case .subheading:
                Font.Subheading.medium.lineHeight

            case .caption:
                Font.Caption.medium.lineHeight
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .display:
                CornerRadius._150

            case .headingMedium:
                CornerRadius._100

            case .headingSmall, .body, .subheading, .caption:
                CornerRadius._200
            }
        }

        /// Share of the parent width the bar occupies, per Figma `Shimmer / Text` defaults.
        var widthRatio: CGFloat {
            switch self {
            case .display:
                0.5

            case .headingMedium:
                0.7

            case .headingSmall:
                0.6

            case .body:
                0.5

            case .subheading:
                0.4

            case .caption:
                0.3
            }
        }

        private typealias Font = DesignSystem.Tokens.Font
        private typealias CornerRadius = DesignSystem.Tokens.CornerRadius
    }
}

// MARK: - Private blocks

private struct TangemShimmerTextBlock: View {
    let style: TangemShimmer.TextStyle

    @ScaledMetric private var height: CGFloat
    @ScaledMetric private var cornerRadius: CGFloat

    init(style: TangemShimmer.TextStyle) {
        self.style = style
        _height = ScaledMetric(wrappedValue: style.lineHeight)
        _cornerRadius = ScaledMetric(wrappedValue: style.cornerRadius)
    }

    var body: some View {
        LeadingRatioWidth(ratio: style.widthRatio) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(DesignSystem.Tokens.Theme.Bg.Opaque.secondary)
                .mask { TangemShimmerShine() }
                .frame(height: height)
        }
    }
}

/// Lays a single subview out at `ratio` of the proposed width, pinned to the leading edge,
/// while the layout itself reports the full proposed width — so it fills the line like text
/// would, without `GeometryReader`'s greedy, intrinsic-size-less behavior.
private struct LeadingRatioWidth: Layout {
    let ratio: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let bar = subviews.first?.sizeThatFits(.unspecified) ?? .zero
        return CGSize(width: proposal.width ?? bar.width, height: bar.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(
            at: CGPoint(x: bounds.minX, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width * ratio, height: bounds.height)
        )
    }
}

private struct TangemShimmerCustomBlock: View {
    let width: CGFloat?
    let height: CGFloat?
    let cornerRadius: CGFloat?

    /// Unit metric used as a Dynamic Type multiplier so fixed sizes scale like the text variant.
    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        let scaledWidth = width.map { $0 * scale }
        let scaledHeight = height.map { $0 * scale }
        let resolvedCornerRadius: CGFloat = cornerRadius ?? (scaledHeight.map { $0 / 2 } ?? 0)
        return RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous)
            .fill(DesignSystem.Tokens.Theme.Bg.Opaque.secondary)
            .mask { TangemShimmerShine() }
            .frame(width: scaledWidth, height: scaledHeight)
    }
}
