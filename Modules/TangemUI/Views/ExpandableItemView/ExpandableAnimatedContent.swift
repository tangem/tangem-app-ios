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
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Views

    private var expandedContentWithTransition: some View {
        expandedContent
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
