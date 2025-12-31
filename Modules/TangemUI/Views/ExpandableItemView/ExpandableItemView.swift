//
//  ExpandableItemView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
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
    private let onExpandedChange: ((_ isExpanded: Bool) -> Void)?
    private let isExpandedExternal: Bool

    // MARK: - Init

    /// - Note: `onExpandedChange` is called only on user interaction, not on initial state setup or programmatic changes.
    public init(
        isExpanded: Bool,
        backgroundColor: Color = Colors.Background.primary,
        cornerRadius: CGFloat = 14,
        initialCollapsedHeight: CGFloat = 0,
        initialExpandedHeight: CGFloat = 0,
        @ViewBuilder collapsedView: () -> CollapsedView,
        @ViewBuilder expandedView: () -> ExpandedView,
        @ViewBuilder expandedViewHeader: () -> ExpandedViewHeader,
        onExpandedChange: ((_ isExpanded: Bool) -> Void)? = nil
    ) {
        _animationProgress = .init(initialValue: Self.animationProgress(isExpanded: isExpanded))
        isExpandedExternal = isExpanded
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

    @State private var animationProgress: Double

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
        .buttonStyle(.scaled(
            scaleAmount: isExpanded ? 1.0 : 0.98,
            dimmingAmount: isExpanded ? 1.0 : 0.7
        ))
        .onChange(of: isExpandedExternal) { newValue in
            setExpanded(isExpanded: newValue, notifyOnChange: false)
        }
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
        FeedbackGenerator.selectionChanged()
        setExpanded(isExpanded: !isExpanded, notifyOnChange: true)
    }

    private func setExpanded(isExpanded: Bool, notifyOnChange: Bool) {
        // Actual curve is set in ExpandableAnimatedContent
        withAnimation(.linear(duration: 0.5)) {
            animationProgress = Self.animationProgress(isExpanded: isExpanded)
            if notifyOnChange {
                onExpandedChange?(isExpanded)
            }
        }
    }

    private static func animationProgress(isExpanded: Bool) -> Double {
        isExpanded ? 1.0 : 0.0
    }
}
