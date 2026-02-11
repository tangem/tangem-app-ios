//
//  ExpandableItemView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemAssets
import TangemUIUtils

public struct ExpandableItemView<
    CollapsedView: View,
    ExpandedView: View,
    ExpandedViewHeader: View
>: View {
    // MARK: - Dependencies

    private let collapsedView: CollapsedView
    private let expandedView: ExpandedView
    private let expandedViewHeaderBuilder: () -> ExpandedViewHeader
    private let backgroundColor: Color
    private let cornerRadius: CGFloat
    private let backgroundGeometryEffect: GeometryEffectPropertiesModel?
    private let expandedViewTransition: AnyTransition?
    private let onExpandedChange: ((_ isExpanded: Bool) -> Void)?
    private let isExpandedExternal: Bool

    // MARK: - Init

    /// - Note: `onExpandedChange` is called only on user interaction, not on initial state setup or programmatic changes.
    public init(
        isExpanded: Bool,
        backgroundColor: Color = Colors.Background.primary,
        cornerRadius: CGFloat = 14,
        backgroundGeometryEffect: GeometryEffectPropertiesModel? = nil,
        expandedViewTransition: AnyTransition? = nil,
        @ViewBuilder collapsedView: () -> CollapsedView,
        @ViewBuilder expandedView: () -> ExpandedView,
        @ViewBuilder expandedViewHeader: @escaping () -> ExpandedViewHeader,
        onExpandedChange: ((_ isExpanded: Bool) -> Void)? = nil
    ) {
        _isExpanded = .init(initialValue: isExpanded)
        _isExpandedContentVisible = .init(initialValue: isExpanded)
        isExpandedExternal = isExpanded
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.backgroundGeometryEffect = backgroundGeometryEffect
        self.expandedViewTransition = expandedViewTransition
        self.onExpandedChange = onExpandedChange
        self.collapsedView = collapsedView()
        self.expandedView = expandedView()
        expandedViewHeaderBuilder = expandedViewHeader
    }

    // MARK: - State

    /// Controls which view is displayed (collapsed vs expanded header).
    @State private var isExpanded: Bool
    /// Controls expanded content visibility separately from `isExpanded` to create staged animation:
    /// on expand, content appears with slight delay after container starts expanding.
    @State private var isExpandedContentVisible: Bool

    // MARK: - Body

    public var body: some View {
        Button(action: toggleExpanded) {
            ExpandableAnimatedContent(
                collapsedView: collapsedView
                    .contentShape(Rectangle()),
                expandedHeader: expandedHeaderView,
                expandedContent: expandedView,
                backgroundColor: backgroundColor,
                cornerRadius: cornerRadius,
                isExpanded: isExpanded,
                showExpandedContent: isExpandedContentVisible,
                backgroundGeometryEffect: backgroundGeometryEffect,
                expandedContentTransition: expandedViewTransition
            )
        }
        .buttonStyle(.scaled(
            scaleAmount: isExpanded ? 1.0 : 0.98,
            dimmingAmount: isExpanded ? 1.0 : 0.7
        ))
        .onChange(of: isExpandedExternal, perform: handleExternalExpandedChange)
    }

    // MARK: - Views

    private var expandedHeaderView: some View {
        expandedViewHeaderBuilder()
            .contentShape(Rectangle())
            .onTapGesture(perform: toggleExpanded)
    }

    // MARK: - Animation Control

    private func toggleExpanded() {
        FeedbackGenerator.selectionChanged()
        setExpanded(!isExpanded, notifyOnChange: true)
    }

    private func setExpanded(_ expanded: Bool, notifyOnChange: Bool) {
        if expanded {
            expand()
        } else {
            collapse()
        }

        if notifyOnChange {
            onExpandedChange?(expanded)
        }
    }

    private func expand() {
        withAnimation(Constants.containerAnimation) {
            isExpanded = true
        }

        // Content appears with slight delay for smoother transition
        withAnimation(Constants.containerAnimation.delay(Constants.expandedContentDelay)) {
            isExpandedContentVisible = true
        }
    }

    private func collapse() {
        withAnimation(Constants.containerAnimation) {
            isExpanded = false
            isExpandedContentVisible = false
        }
    }

    // MARK: - Callbacks

    private func handleExternalExpandedChange(_ newValue: Bool) {
        setExpanded(newValue, notifyOnChange: false)
    }
}

// MARK: - Constants

private extension ExpandableItemView {
    enum Constants {
        static var animationDuration: CGFloat { 0.3 }
        static var containerAnimation: Animation { .easeInOut(duration: animationDuration) }
        /// Delay before showing expanded content, as a fraction of total animation duration
        static var expandedContentDelay: CGFloat { animationDuration / 6 }
    }
}
