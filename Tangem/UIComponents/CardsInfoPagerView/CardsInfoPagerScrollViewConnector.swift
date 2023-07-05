//
//  CardsInfoPagerScrollViewConnector.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardsInfoPagerScrollViewConnector {
    let contentOffset: Binding<CGPoint>
    var headerPlaceholderView: some View { _headerPlaceholderView }

    private let _headerPlaceholderView: CardsInfoPageHeaderPlaceholderView

    private let headerPlaceholderTopInset: CGFloat
    private let headerPlaceholderHeight: CGFloat

    init(
        contentOffset: Binding<CGPoint>,
        headerPlaceholderView: CardsInfoPageHeaderPlaceholderView,
        headerPlaceholderTopInset: CGFloat,
        headerPlaceholderHeight: CGFloat
    ) {
        self.contentOffset = contentOffset
        _headerPlaceholderView = headerPlaceholderView
        self.headerPlaceholderTopInset = headerPlaceholderTopInset
        self.headerPlaceholderHeight = headerPlaceholderHeight
    }

    /// Calculates height for the ScrollView footer, which allows the ScrollView header
    /// to collapse when there is not enough content in the ScrollView.
    func footerViewHeight(
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
