//
//  CardsInfoPageHeaderPlaceholderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// This placeholder must be inserted into `List`/`ScrollView` for vertical scrolling to work.
/// Required when pages in `CardsInfoPagerView` have nested `ScrollView` or `List`
/// See examples in the preview section for `CardsInfoPagerView` (`DummyCardInfoPageView` page view).
struct CardsInfoPageHeaderPlaceholderView: View {
    @Environment(\.cardsInfoPageHeaderPlaceholderHeight) private var headerPlaceholderHeight

    // `any Hashable` won't compile in the view's body because `ViewBuilder` requires concrete types
    let expandedHeaderScrollTargetIdentifier: AnyHashable
    let collapsedHeaderScrollTargetIdentifier: AnyHashable

    let headerPlaceholderTopInset: CGFloat

    var body: some View {
        VStack(spacing: 0.0) {
            Group {
                Color.clear
                    .frame(height: headerPlaceholderHeight)
                    .padding(.top, headerPlaceholderTopInset)
                    .id(expandedHeaderScrollTargetIdentifier)

                Color.clear
                    .frame(height: 0.0)
                    .id(collapsedHeaderScrollTargetIdentifier)
            }
            .frame(idealWidth: .infinity)
            .listRowInsets(EdgeInsets())
        }
    }
}
