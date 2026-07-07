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
/// TangemShimmer().variant(.text(style: .body))                          // bar fills the style's default share of the parent
/// TangemShimmer().variant(.text(style: .body, alignment: .center))
/// TangemShimmer().variant(.custom(width: 100, height: 24))
/// ```
public struct TangemShimmer: View {
    private var variant: Variant = .custom()

    public init() {}

    public var body: some View {
        switch variant {
        case .text(let style, let alignment):
            TangemShimmerTextBlock(style: style, alignment: alignment)

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
        case text(style: TextStyle, alignment: Alignment = .leading)
        case custom(width: CGFloat? = nil, height: CGFloat? = nil, cornerRadius: CGFloat? = nil)
    }

    enum Alignment: Hashable, Sendable {
        case leading
        case center
        case trailing
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
                DesignSystem.Font.displayMediumToken.lineHeight

            case .headingMedium:
                DesignSystem.Font.headingMediumToken.lineHeight

            case .headingSmall:
                DesignSystem.Font.headingSmallToken.lineHeight

            case .body:
                DesignSystem.Font.bodyMediumToken.lineHeight

            case .subheading:
                DesignSystem.Font.subheadingMediumToken.lineHeight

            case .caption:
                DesignSystem.Font.captionMediumToken.lineHeight
            }
        }

        /// Inner top/bottom inset so the animated bar is glyph-sized rather than line-sized,
        /// while the placeholder keeps the full line-height footprint. Per Figma `Shimmer / Text` spec.
        var verticalPadding: CGFloat {
            switch self {
            case .display:
                4

            case .headingMedium, .headingSmall, .body, .subheading, .caption:
                2
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .display:
                12

            case .headingMedium:
                8

            case .headingSmall, .body, .subheading, .caption:
                16
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
    }
}

// MARK: - Private blocks

private struct TangemShimmerTextBlock: View {
    let style: TangemShimmer.TextStyle
    let alignment: TangemShimmer.Alignment

    @ScaledMetric private var barHeight: CGFloat
    @ScaledMetric private var cornerRadius: CGFloat
    @ScaledMetric private var verticalPadding: CGFloat

    init(style: TangemShimmer.TextStyle, alignment: TangemShimmer.Alignment) {
        self.style = style
        self.alignment = alignment
        _barHeight = ScaledMetric(wrappedValue: style.lineHeight - 2 * style.verticalPadding)
        _cornerRadius = ScaledMetric(wrappedValue: style.cornerRadius)
        _verticalPadding = ScaledMetric(wrappedValue: style.verticalPadding)
    }

    var body: some View {
        RatioWidth(ratio: style.widthRatio, alignment: alignment) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(DesignSystem.Color.bgOpaqueSecondary)
                .mask { TangemShimmerShine() }
                .frame(height: barHeight)
                .padding(.vertical, verticalPadding)
        }
    }
}

/// Lays a single subview out at `ratio` of the proposed width, pinned to `alignment`,
/// while the layout itself reports the full proposed width — so it fills the line like text
/// would, without `GeometryReader`'s greedy, intrinsic-size-less behavior.
private struct RatioWidth: Layout {
    let ratio: CGFloat
    let alignment: TangemShimmer.Alignment

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let bar = subviews.first?.sizeThatFits(.unspecified) ?? .zero
        return CGSize(width: proposal.width ?? bar.width, height: bar.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width * ratio
        let x: CGFloat = switch alignment {
        case .leading: bounds.minX
        case .center: bounds.midX - width / 2
        case .trailing: bounds.maxX - width
        }
        subviews.first?.place(
            at: CGPoint(x: x, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: width, height: bounds.height)
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
            .fill(DesignSystem.Color.bgOpaqueSecondary)
            .mask { TangemShimmerShine() }
            .frame(width: scaledWidth, height: scaledHeight)
    }
}
