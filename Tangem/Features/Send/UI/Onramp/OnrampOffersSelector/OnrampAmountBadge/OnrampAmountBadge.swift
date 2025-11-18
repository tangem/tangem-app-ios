//
//  OnrampAmountBadge.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct OnrampAmountBadge: View {
    let badge: Badge?

    var body: some View {
        switch badge {
        case .none:
            EmptyView()

        case .best:
            Assets.Express.bestRateStarIcon.image
                .resizable()
                .frame(width: 8, height: 8)
                .padding(2)
                .background(Circle().fill(Colors.Icon.accent))

        case .loss(let percent, let signType):
            Text(percent)
                .style(Fonts.Bold.caption2, color: signType.textColor)
                .padding(.vertical, 1)
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(signType.textColor.opacity(0.1))
                )
        }
    }
}

extension OnrampAmountBadge {
    enum Badge: Hashable {
        case best
        case loss(percent: String, signType: ChangeSignType)
    }
}
