//
//  HorizontalFlowLayout.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct HorizontalFlowLayout<Item: Hashable, ItemContent: View>: View {
    private let items: [Item]
    private let alignment: Alignment
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat
    private let itemContent: (Item) -> ItemContent

    /// Creates a horizontal flow layout view.
    ///
    /// - Parameters:
    ///   - items: The array of items to display in the layout.
    ///   - alignment: Alignment of items inside each row.
    ///   - horizontalSpacing: Spacing between items in the same row.
    ///   - verticalSpacing: Spacing between rows.
    ///   - itemContent: A closure that returns a view for each item.
    public init(
        items: [Item],
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat = 20,
        verticalSpacing: CGFloat = 20,
        @ViewBuilder itemContent: @escaping (Item) -> ItemContent
    ) {
        self.items = items
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.itemContent = itemContent
    }

    public var body: some View {
        WrappingHStack(alignment: alignment, horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing) {
            ForEach(items, id: \.self) {
                itemContent($0)
            }
        }
    }
}
