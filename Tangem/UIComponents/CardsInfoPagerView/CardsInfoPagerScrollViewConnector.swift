//
//  CardsInfoPagerScrollViewConnector.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardsInfoPagerScrollViewConnector: CardsInfoPagerScrollViewConnectable {
    let contentOffset: Binding<CGPoint>

    var placeholderView: some View { headerPlaceholderView }

    private let headerPlaceholderView: CardsInfoPageHeaderPlaceholderView

    private let expandedHeaderScrollTargetIdentifier: any Hashable
    private let collapsedHeaderScrollTargetIdentifier: any Hashable

    private let headerPlaceholderTopInset: CGFloat
    private let headerPlaceholderHeight: CGFloat

    init(
        headerPlaceholderView: CardsInfoPageHeaderPlaceholderView,
        headerPlaceholderTopInset: CGFloat,
        headerPlaceholderHeight: CGFloat,
        contentOffset: Binding<CGPoint>,
        expandedHeaderScrollTargetIdentifier: any Hashable,
        collapsedHeaderScrollTargetIdentifier: any Hashable
    ) {
        self.headerPlaceholderView = headerPlaceholderView
        self.headerPlaceholderTopInset = headerPlaceholderTopInset
        self.headerPlaceholderHeight = headerPlaceholderHeight
        self.contentOffset = contentOffset
        self.expandedHeaderScrollTargetIdentifier = expandedHeaderScrollTargetIdentifier
        self.collapsedHeaderScrollTargetIdentifier = collapsedHeaderScrollTargetIdentifier
    }

    func performScrollIfNeeded(with scrollViewProxy: ScrollViewProxy) {
        let yOffset = contentOffset.wrappedValue.y - headerPlaceholderTopInset

        guard 0.0 ..< headerPlaceholderHeight ~= yOffset else { return }

        withAnimation(.spring()) {
            if yOffset > headerPlaceholderHeight / 2.0 {
                scrollViewProxy.scrollTo(collapsedHeaderScrollTargetIdentifier, anchor: .top)
            } else {
                scrollViewProxy.scrollTo(expandedHeaderScrollTargetIdentifier, anchor: .top)
            }
        }
    }

    /// Calculates height for the ScrollView footer, which allows the ScrollView header
    /// to collapse when there is not enough content in the ScrollView.
    func scrollViewFooterHeight(
        viewportSize: CGSize,
        contentSize: CGSize
    ) -> CGFloat {
        let minContentSizeHeight = viewportSize.height + .ulpOfOne
        let maxContentSizeHeight = viewportSize.height + headerPlaceholderHeight + headerPlaceholderTopInset

        if (minContentSizeHeight ..< maxContentSizeHeight) ~= contentSize.height {
            return maxContentSizeHeight - contentSize.height
        }

        return 0.0
    }
}
