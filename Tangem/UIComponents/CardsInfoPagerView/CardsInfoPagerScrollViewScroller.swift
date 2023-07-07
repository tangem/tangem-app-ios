//
//  CardsInfoPagerScrollViewScroller.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardsInfoPagerScrollViewScroller {
    enum ProposedHeaderState {
        case collapsed
        case expanded
    }

    private let contentOffset: Binding<CGPoint>

    private let headerPlaceholderTopInset: CGFloat
    private let headerPlaceholderHeight: CGFloat
    private let headerAutoScrollThresholdRatio: CGFloat

    private let expandedHeaderScrollTargetIdentifier: any Hashable
    private let collapsedHeaderScrollTargetIdentifier: any Hashable

    init(
        contentOffset: Binding<CGPoint>,
        headerPlaceholderTopInset: CGFloat,
        headerPlaceholderHeight: CGFloat,
        headerAutoScrollThresholdRatio: CGFloat,
        expandedHeaderScrollTargetIdentifier: any Hashable,
        collapsedHeaderScrollTargetIdentifier: any Hashable
    ) {
        self.contentOffset = contentOffset
        self.headerPlaceholderTopInset = headerPlaceholderTopInset
        self.headerPlaceholderHeight = headerPlaceholderHeight
        self.headerAutoScrollThresholdRatio = headerAutoScrollThresholdRatio
        self.expandedHeaderScrollTargetIdentifier = expandedHeaderScrollTargetIdentifier
        self.collapsedHeaderScrollTargetIdentifier = collapsedHeaderScrollTargetIdentifier
    }

    func performScrollIfNeeded(
        with scrollViewProxy: ScrollViewProxy,
        proposedState: ProposedHeaderState
    ) {
        let yOffset = contentOffset.wrappedValue.y - headerPlaceholderTopInset

        guard (0.0 ..< headerPlaceholderHeight) ~= yOffset else { return }

        let headerAutoScrollRatio = proposedState == .collapsed
            ? headerAutoScrollThresholdRatio
            : 1.0 - headerAutoScrollThresholdRatio

        withAnimation(.spring()) {
            if yOffset > headerPlaceholderHeight * headerAutoScrollRatio {
                scrollViewProxy.scrollTo(collapsedHeaderScrollTargetIdentifier, anchor: .top)
            } else {
                scrollViewProxy.scrollTo(expandedHeaderScrollTargetIdentifier, anchor: .top)
            }
        }
    }
}
