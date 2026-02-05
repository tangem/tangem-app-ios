//
//  ExpandableItemAnimationModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

// MARK: - Expandable Animated Content

struct ExpandableAnimatedContent<CollapsedView: View, ExpandedHeader: View, ExpandedContent: View>: View {
    let collapsedView: CollapsedView
    let expandedHeader: ExpandedHeader
    let expandedContent: ExpandedContent
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let isExpanded: Bool
    let showExpandedContent: Bool
    let backgroundGeometryEffect: GeometryEffectPropertiesModel?
    let expandedContentTransition: AnyTransition?

    var body: some View {
        ZStack(alignment: .top) {
            if isExpanded {
                VStack(spacing: 8) {
                    expandedHeader

                    if showExpandedContent {
                        expandedContentWithTransition
                    }
                }
            } else {
                collapsedView
            }
        }
        // Do not apply cornerRadius to the view directly to avoid clipping iOS context menus.
        // Apply clipShape only during animations to prevent content overflow during transitions.
        .background(background.cornerRadiusContinuous(cornerRadius))
        .clipShape(TransitionClipShape(
            progress: isExpanded ? 1 : 0,
            cornerRadius: cornerRadius
        ))
    }

    // MARK: - Views

    private var expandedContentWithTransition: some View {
        expandedContent
            // Prevents the expand/collapse transition animation from being inherited by the
            // expanded content's subviews (headers and token rows), which would otherwise cause
            // them to "fly in" from their matched geometry positions instead of appearing in place
            .disableAnimations()
            .ifLet(
                expandedContentTransition,
                transform: { view, transition in
                    view.transition(transition)
                }
            )
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(backgroundColor)
            .matchedGeometryEffect(backgroundGeometryEffect)
    }
}

// MARK: - TransitionClipShape

/// A custom `Shape` that clips content only during expand/collapse animations.
/// At rest (progress ≈ 0 or ≈ 1), the path extends far beyond bounds so nothing
/// is effectively clipped — context menus, shadows, and overflow work normally.
/// During animation, the path is a standard rounded rect that prevents content overflow.
private struct TransitionClipShape: Shape {
    var progress: CGFloat
    let cornerRadius: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let isTransitioning = progress > CGFloat.ulpOfOne && progress < 1 - CGFloat.ulpOfOne

        if isTransitioning {
            return Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
        }

        // Oversized rect — effectively no clipping.
        return Path(rect.insetBy(dx: -10000, dy: -10000))
    }
}
