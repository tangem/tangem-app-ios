//
//  NewsScoreBadgeView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct NewsScoreBadgeView: View {
    let score: String

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .foregroundStyle(Color.Tangem.Graphic.Status.attention)
                    .frame(size: .init(bothDimensions: 12))

                Assets.star.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 7))
                    .foregroundStyle(Color.Tangem.Graphic.Neutral.primaryInverted)
            }

            Text(score)
        }
    }
}
