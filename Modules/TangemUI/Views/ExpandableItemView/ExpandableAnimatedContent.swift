//
//  ExpandableItemAnimationModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemUIUtils

// MARK: - Expandable Animated Content

struct ExpandableAnimatedContent<CollapsedView: View, ExpandedView: View>: Animatable, View {
    let collapsedView: CollapsedView
    let expandedView: ExpandedView
    let backgroundColor: Color
    let cornerRadius: CGFloat
    var progress: Double

    @State private var expandedHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0

    @Environment(\.displayScale) private var displayScale

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        ZStack(alignment: .top) {
            background

            collapsedContent
                .opacity(collapsedOpacity)
                .offset(y: collapsedOffset)

            if shouldShowExpandedContent {
                expandedContent
                    .opacity(expandedOpacity)
                    .offset(y: expandedOffset)
            }
        }
        .frame(height: interpolatedHeight, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Views

    private var background: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(backgroundColor)
    }

    private var collapsedContent: some View {
        collapsedView
            .fixedSize(horizontal: false, vertical: true)
            .readGeometry(\.size.height) { height in
                if abs(collapsedHeight - height) > (1.0 / displayScale) {
                    collapsedHeight = height
                }
            }
    }

    private var expandedContent: some View {
        expandedView
            .fixedSize(horizontal: false, vertical: true)
            .readGeometry(\.size.height) { height in
                if abs(expandedHeight - height) > (1.0 / displayScale) {
                    expandedHeight = height
                }
            }
    }

    // MARK: - Settings

    private var shouldShowExpandedContent: Bool {
        progress > 0
    }

    private var interpolatedHeight: CGFloat {
        guard collapsedHeight > 0 else { return 0 }
        let targetHeight = expandedHeight > 0 ? expandedHeight : collapsedHeight
        let heightDifference = targetHeight - collapsedHeight
        return max(collapsedHeight + heightDifference * easedProgress, 0)
    }

    private var collapsedOpacity: Double {
        1.0 - easedProgress
    }

    private var expandedOpacity: Double {
        easedProgress
    }

    private var collapsedOffset: Double {
        -collapsedHeight * easedProgress
    }

    private var expandedOffset: Double {
        collapsedHeight * (1.0 - easedProgress)
    }

    private var easedProgress: Double {
        // Ease-in-out quart curve: faster acceleration and deceleration
        let coefficient = ExpandableAnimatedContentConstants.quartEasingCoefficient

        let remainingProgress = 1 - progress

        let easedProgress = if progress < ExpandableAnimatedContentConstants.phaseDivisionThreshold {
            coefficient * pow(progress, 4)
        } else {
            1 - coefficient * pow(remainingProgress, 4)
        }

        return clamp(easedProgress, min: 0, max: 1)
    }
}

// MARK: - Constants

enum ExpandableAnimatedContentConstants {
    static let phaseDivisionThreshold: Double = 0.5

    /// Coefficient for easeInOutQuart curve (2^(n-1) where n=4 for quart)
    fileprivate static let quartEasingCoefficient: Double = 8
}
