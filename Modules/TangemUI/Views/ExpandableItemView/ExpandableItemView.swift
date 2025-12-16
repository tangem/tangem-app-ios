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
    private let onExpandedChange: ((Bool) -> Void)?

    public init(
        backgroundColor: Color = Colors.Background.primary,
        cornerRadius: CGFloat = 14,
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
    }

    // MARK: - State

    @State private var isExpanded = false
    @Namespace private var namespace
    @State private var isAnimating = false
    @State private var isPressed = false

    // MARK: - Body

    public var body: some View {
        if isExpanded {
            ExpandedContentWrapperView(
                header: expandedViewHeader,
                content: expandedView,
                onTap: toggleExpanded
            )
            // Mikhail Andreev - can't extract those to reusable properties because then matchedGeometryEffect behaves funny
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
                    .matchedGeometryEffect(id: Constants.backgroundGeometryEffectID, in: namespace)
            )
            .mask(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .matchedGeometryEffect(id: Constants.maskGeometryEffectID, in: namespace)
            )
        } else {
            collapsedView
                .transition(.collapsedViewTransition)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundColor)
                        .matchedGeometryEffect(id: Constants.backgroundGeometryEffectID, in: namespace)
                )
                .mask(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .matchedGeometryEffect(id: Constants.maskGeometryEffectID, in: namespace)
                )
                .transformEffect(.identity)
                .onTapGesture(perform: toggleExpanded)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }

    // MARK: - Private functions

    private func toggleExpanded() {
        // [REDACTED_TODO_COMMENT]
        guard !isAnimating else { return }

        isAnimating = true

        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isPressed = false
                isExpanded.toggle()
            }

            onExpandedChange?(isExpanded)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAnimating = false
            }
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let cornerRadius: CGFloat = 14
    static let backgroundGeometryEffectID = "cardBG"
    static let maskGeometryEffectID = "cardMask"
}
