//
//  FullPagePagerBodyContainer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Shared body container used by both Modern (iOS 17+) and Legacy (iOS 16) implementations.
/// Renders only the visible pages based on scroll offset for memory efficiency.
struct FullPagePagerBodyContainer<Data, Content>: View
    where Data: RandomAccessCollection,
    Data.Element: Identifiable,
    Data.Index == Int,
    Content: View {
    let data: Data
    let scrollOffset: CGFloat
    let pageWidth: CGFloat
    let contentFactory: (Data.Element) -> Content

    var body: some View {
        let visibleIndices = FullPagePagerViewHelper.visiblePageIndices(
            scrollOffset: scrollOffset,
            pageWidth: pageWidth,
            pageCount: data.count
        )

        ZStack(alignment: .leading) {
            ForEach(visibleIndices, id: \.self) { index in
                let element = data[data.index(data.startIndex, offsetBy: index)]

                ScrollView(.vertical, showsIndicators: false) {
                    contentFactory(element)
                }
                .frame(width: pageWidth)
                .offset(x: CGFloat(index) * pageWidth - scrollOffset)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(maxHeight: .infinity, alignment: .leading)
        .frame(width: pageWidth)
        .clipped()
    }
}
