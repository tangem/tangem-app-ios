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

    private let namespace: Namespace.ID
    private let matchedGeometryEffectId: String
    private let isHeaderPlaceholderVisible: Binding<Bool>

    var body: some View {
        Color.clear
            .frame(idealWidth: .infinity)
            .frame(height: headerPlaceholderHeight)
            .matchedGeometryEffect(id: matchedGeometryEffectId, in: namespace, isSource: true)
            .onAppear {
                // [REDACTED_TODO_COMMENT]
                isHeaderPlaceholderVisible.wrappedValue = true
            }
            .onDisappear {
                // [REDACTED_TODO_COMMENT]
                isHeaderPlaceholderVisible.wrappedValue = false
            }
            .listRowInsets(EdgeInsets())
    }

    init(
        namespace: Namespace.ID,
        matchedGeometryEffectId: String,
        isHeaderPlaceholderVisible: Binding<Bool>
    ) {
        self.namespace = namespace
        self.matchedGeometryEffectId = matchedGeometryEffectId
        self.isHeaderPlaceholderVisible = isHeaderPlaceholderVisible
    }
}
