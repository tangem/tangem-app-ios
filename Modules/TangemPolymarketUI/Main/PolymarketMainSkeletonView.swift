//
//  PolymarketMainSkeletonView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

public struct PolymarketCategoriesSkeletonView: View {
    public init() {}

    public var body: some View {
        TabNavigation(data: Constants.tabs, selection: .constant(Constants.tabs[0]))
            .variant(.material)
            .scrollable()
            .loading(true)
    }
}

public struct PolymarketEventsSkeletonView: View {
    public init() {}

    public var body: some View {
        ForEach(0 ..< Constants.cardCount, id: \.self) { _ in
            PolymarketEventCardSkeleton()
                .padding(.horizontal, Constants.horizontalPadding)
        }
    }
}

// MARK: - Constants

private extension PolymarketCategoriesSkeletonView {
    enum Constants {
        static let tabCount = 5
        static let tabs: [PolymarketCategoryTab] = (0 ..< tabCount).map { PolymarketCategoryTab(id: $0, title: "") }
    }
}

private extension PolymarketEventsSkeletonView {
    enum Constants {
        static let cardCount = 10
        static let horizontalPadding: CGFloat = 16
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 12) {
        PolymarketCategoriesSkeletonView()
        PolymarketEventsSkeletonView()
    }
}
