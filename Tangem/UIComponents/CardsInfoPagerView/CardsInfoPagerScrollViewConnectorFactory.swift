//
//  CardsInfoPagerScrollViewConnectorFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardsInfoPagerScrollViewConnectorFactory {
    let headerPlaceholderTopInset: CGFloat
    let headerAutoScrollThresholdRatio: CGFloat
    let headerPlaceholderHeight: CGFloat
    let contentOffset: Binding<CGPoint>

    func makeConnector(forPageAtIndex pageIndex: Int) -> CardsInfoPagerScrollViewConnector {
        let expandedHeaderScrollTargetIdentifier = "expandedHeaderScrollTargetIdentifier_\(pageIndex)"
        let collapsedHeaderScrollTargetIdentifier = "collapsedHeaderScrollTargetIdentifier_\(pageIndex)"

        let headerPlaceholderView = CardsInfoPageHeaderPlaceholderView(
            expandedHeaderScrollTargetIdentifier: expandedHeaderScrollTargetIdentifier,
            collapsedHeaderScrollTargetIdentifier: collapsedHeaderScrollTargetIdentifier,
            headerPlaceholderTopInset: headerPlaceholderTopInset
        )
        return CardsInfoPagerScrollViewConnector(
            headerPlaceholderView: headerPlaceholderView,
            headerPlaceholderTopInset: headerPlaceholderTopInset,
            headerPlaceholderHeight: headerPlaceholderHeight,
            headerAutoScrollThresholdRatio: headerAutoScrollThresholdRatio,
            contentOffset: contentOffset,
            expandedHeaderScrollTargetIdentifier: expandedHeaderScrollTargetIdentifier,
            collapsedHeaderScrollTargetIdentifier: collapsedHeaderScrollTargetIdentifier
        )
    }
}
