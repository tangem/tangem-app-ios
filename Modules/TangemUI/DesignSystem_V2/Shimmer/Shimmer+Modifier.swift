//
//  Shimmer+Modifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public extension View {
    func shimmering() -> some View {
        modifier(ShimmeringModifier(isActive: false))
    }

    func shimmering(_ isActive: Bool) -> some View {
        modifier(ShimmeringModifier(isActive: isActive))
    }

    func shimmerPlaceholder(_ isShown: Bool, variant: Shimmer.Variant? = nil) -> some View {
        modifier(ShimmerPlaceholderModifier(isShown: isShown, variant: variant))
    }
}

private struct ShimmeringModifier: ViewModifier {
    let isActive: Bool

    @Environment(\.isShimmerActive) private var isShimmerActive

    func body(content: Content) -> some View {
        if isActive || isShimmerActive {
            content
                .mask { ShimmerShine() }
                .drawingGroup()
        } else {
            content
        }
    }
}

private struct ShimmerPlaceholderModifier: ViewModifier {
    let isShown: Bool
    let variant: Shimmer.Variant?

    func body(content: Content) -> some View {
        let hiddenContent = content
            .hidden(isShown)
            .allowsHitTesting(!isShown)
            .accessibilityHidden(isShown)

        switch layout {
        case .matchContent(let cornerRadius):
            hiddenContent
                .overlay {
                    Shimmer()
                        .variant(.custom(cornerRadius: cornerRadius))
                        .hidden(!isShown)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

        case .sized(let variant):
            ShimmerPlaceholderLayout(isShown: isShown) {
                hiddenContent

                Shimmer()
                    .variant(variant)
                    .hidden(!isShown)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    private var layout: Layout {
        switch variant {
        case .none:
            .matchContent(cornerRadius: Self.defaultCornerRadius)
        case .some(.custom(.none, .none, let cornerRadius)):
            .matchContent(cornerRadius: cornerRadius ?? Self.defaultCornerRadius)
        case .some(let variant):
            .sized(variant)
        }
    }

    private static let defaultCornerRadius: CGFloat = 8

    private enum Layout {
        case matchContent(cornerRadius: CGFloat)
        case sized(Shimmer.Variant)
    }
}

private struct ShimmerPlaceholderLayout: Layout {
    let isShown: Bool

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else {
            return subviews.first?.sizeThatFits(proposal) ?? .zero
        }

        let content = subviews[0].sizeThatFits(proposal)

        guard isShown else {
            return content
        }

        let block = subviews[1].sizeThatFits(ProposedViewSize(width: proposal.width ?? content.width, height: proposal.height))
        return CGSize(width: block.width, height: max(block.height, content.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (index, subview) in subviews.enumerated() {
            let subviewProposal = index == 0 ? proposal : ProposedViewSize(width: proposal.width ?? bounds.width, height: proposal.height)
            let size = subview.sizeThatFits(subviewProposal)
            subview.place(
                at: CGPoint(x: bounds.midX, y: bounds.midY),
                anchor: .center,
                proposal: ProposedViewSize(size)
            )
        }
    }
}
