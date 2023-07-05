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

        guard yOffset > 0.0 else { return }

        withAnimation(.spring()) {
            if yOffset > headerPlaceholderHeight / 2.0 {
                scrollViewProxy.scrollTo(collapsedHeaderScrollTargetIdentifier, anchor: .top)
            } else {
                scrollViewProxy.scrollTo(expandedHeaderScrollTargetIdentifier, anchor: .top)
            }
        }
    }
}
