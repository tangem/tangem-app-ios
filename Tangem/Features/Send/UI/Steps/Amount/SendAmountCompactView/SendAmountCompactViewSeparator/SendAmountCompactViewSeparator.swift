//
//  SendAmountCompactViewSeparator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct SendAmountCompactViewSeparator: View {
    let style: SeparatorStyle

    var body: some View {
        ZStack(alignment: .center) {
            HorizontalLine()
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 7]))
                .foregroundStyle(DesignSystem.Color.bgPrimary)
                .frame(height: 3)

            separatorTitle
                .background(DesignSystem.Color.bgPrimary)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var separatorTitle: some View {
        switch style {
        case .title(let title):
            Text(title)
                .style(Fonts.Regular.caption1, color: DesignSystem.Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        case .swapIcon:
            Assets.swappingIcon.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 20, height: 20)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .padding(4)
        }
    }
}

extension SendAmountCompactViewSeparator {
    enum SeparatorStyle: Hashable {
        case title(String)
        case swapIcon
    }
}
