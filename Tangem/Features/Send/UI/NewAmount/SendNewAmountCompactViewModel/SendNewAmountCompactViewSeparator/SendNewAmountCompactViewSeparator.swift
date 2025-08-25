//
//  SendNewAmountCompactViewSeparator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct SendNewAmountCompactViewSeparator: View {
    let style: SeparatorStyle

    var body: some View {
        ZStack(alignment: .center) {
            Line()
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4]))
                .foregroundStyle(Colors.Background.tertiary)
                .frame(height: 3)
                .offset(y: 1.5)

            separatorTitle
                .background(Colors.Background.tertiary)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var separatorTitle: some View {
        switch style {
        case .title(let title):
            Text(title)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        case .swapIcon:
            Assets.swappingIcon.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 20, height: 20)
                .foregroundStyle(Colors.Icon.primary1)
                .padding(4)
        }
    }
}

extension SendNewAmountCompactViewSeparator {
    enum SeparatorStyle: Hashable {
        case title(String)
        case swapIcon
    }
}

private extension SendNewAmountCompactViewSeparator {
    struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            return path
        }
    }
}
