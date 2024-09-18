//
//  MarketsTokenDetailsChipsContainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct MarketsTokenDetailsChipsContainer: View {
    let chipsData: [MarketsTokenDetailsLinkChipsData]
    let parentWidth: CGFloat
    var horizontalItemsSpacing: CGFloat = 12
    var verticalItemsSpacing: CGFloat = 12

    private let chipsSettings = MarketsTokenDetailsLinkChipsView.StyleSettings(
        iconColor: Colors.Icon.secondary,
        textColor: Colors.Text.secondary,
        backgroundColor: Colors.Background.tertiary,
        font: Fonts.Bold.caption1
    )

    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        ZStack(alignment: .topLeading, content: {
            ForEach(chipsData) { data in
                MarketsTokenDetailsLinkChipsView(
                    text: data.text,
                    icon: data.icon,
                    style: chipsSettings,
                    action: data.action
                )
                .alignmentGuide(.leading) { dimension in
                    if abs(width - dimension.width) > parentWidth {
                        width = 0
                        height -= dimension.height + verticalItemsSpacing
                    }
                    let result = width
                    if data.id == chipsData.last?.id {
                        width = 0
                    } else {
                        width -= dimension.width + horizontalItemsSpacing
                    }
                    return result
                }
                .alignmentGuide(.top) { dimension in
                    let result = height
                    if data.id == chipsData.last?.id {
                        height = 0
                    }
                    return result
                }
            }

            // We need this view to fix items vertical alignment.
            // SwiftUI on iOS 18 not correctly align elements in ZStack, it moves items up O_o
            Color.clear
                .frame(width: 1)
        })
    }
}
