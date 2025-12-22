//
//  ExpandableItemView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils
import TangemAssets

public struct ExpandableItemView<
    CollapsedView: View,
    ExpandedView: View,
    ExpandedViewHeader: View
>: View {
    // MARK: - Dependencies

    private let collapsedView: CollapsedView
    private let expandedView: ExpandedView
    private let expandedViewHeader: ExpandedViewHeader
    private let backgroundColor: Color
    private let cornerRadius: CGFloat
    private let initialCollapsedHeight: CGFloat
    private let initialExpandedHeight: CGFloat
    private let onExpandedChange: ((Bool) -> Void)?

    // MARK: - Init

    public init(
        backgroundColor: Color = Colors.Background.primary,
        cornerRadius: CGFloat = 14,
        initialCollapsedHeight: CGFloat = 0,
        initialExpandedHeight: CGFloat = 0,
        onExpandedChange: ((Bool) -> Void)? = nil,
        @ViewBuilder collapsedView: () -> CollapsedView,
        @ViewBuilder expandedView: () -> ExpandedView,
        @ViewBuilder expandedViewHeader: () -> ExpandedViewHeader
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.onExpandedChange = onExpandedChange
        self.collapsedView = collapsedView()
        self.expandedView = expandedView()
        self.expandedViewHeader = expandedViewHeader()
        self.initialCollapsedHeight = initialCollapsedHeight
        self.initialExpandedHeight = initialExpandedHeight
    }

    // MARK: - State

    @State private var animationProgress: Double = 0.0

    // MARK: - Body

    public var body: some View {
        Button(action: toggleExpanded) {
            ExpandableAnimatedContent(
                collapsedView: collapsedView
                    .contentShape(Rectangle()),
                expandedView: expandedViewWithHeader,
                initialCollapsedHeight: initialCollapsedHeight,
                initialExpandedHeight: initialExpandedHeight,
                backgroundColor: backgroundColor,
                cornerRadius: cornerRadius,
                progress: animationProgress
            )
        }
        .buttonStyle(.scaled(scaleAmount: isExpanded ? 1.0 : 0.98))
    }

    // MARK: - Views

    private var expandedViewWithHeader: some View {
        VStack(spacing: 8) {
            expandedViewHeader
                .contentShape(Rectangle())
                .onTapGesture(perform: toggleExpanded)

            expandedView
        }
    }

    private var isExpanded: Bool {
        animationProgress > ExpandableAnimatedContentConstants.phaseDivisionThreshold
    }

    // MARK: - Private functions

    private func toggleExpanded() {
        // Actual curve is set in ExpandableAnimatedContent
        withAnimation(.linear(duration: 0.5)) {
            animationProgress = isExpanded ? 0.0 : 1.0
            onExpandedChange?(isExpanded)
        }
    }
}
