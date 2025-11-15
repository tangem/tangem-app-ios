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

    public init(
        @ViewBuilder collapsedView: () -> CollapsedView,
        @ViewBuilder expandedView: () -> ExpandedView,
        @ViewBuilder expandedViewHeader: () -> ExpandedViewHeader,
    ) {
        self.collapsedView = collapsedView()
        self.expandedView = expandedView()
        self.expandedViewHeader = expandedViewHeader()
    }

    // MARK: - State

    @State private var isExpanded = false
    @Namespace private var namespace
    @State private var isAnimating = false

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
                RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                    .fill(Colors.Background.primary)
                    .matchedGeometryEffect(id: Constants.backgroundGeometryEffectID, in: namespace)
            )
            .mask(
                RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                    .matchedGeometryEffect(id: Constants.maskGeometryEffectID, in: namespace)
            )
        } else {
            collapsedView
                .transition(.collapsedViewTransition)
                .background(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                        .fill(Colors.Background.primary)
                        .matchedGeometryEffect(id: Constants.backgroundGeometryEffectID, in: namespace)
                )
                .mask(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                        .matchedGeometryEffect(id: Constants.maskGeometryEffectID, in: namespace)
                )
                .transformEffect(.identity)
                .onTapGesture(perform: toggleExpanded)
        }
    }

    // MARK: - Private functions

    private func toggleExpanded() {
        guard !isAnimating else { return }

        isAnimating = true

        withAnimation(.easeInOut(duration: 0.5)) {
            isExpanded.toggle()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = false
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let cornerRadius: CGFloat = 14
    static let backgroundGeometryEffectID = "cardBG"
    static let maskGeometryEffectID = "cardMask"
}
