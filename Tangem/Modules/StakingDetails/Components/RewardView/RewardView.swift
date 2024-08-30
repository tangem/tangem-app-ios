//
//  RewardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct RewardView: View {
    let data: RewardViewData

    var body: some View {
        content
            .padding(.vertical, 8)
            .infinityFrame(axis: .horizontal, alignment: .leading)
    }

    @ViewBuilder
    var content: some View {
        switch data.state {
        case .noRewards:
            Text(Localization.stakingDetailsNoRewardsToClaim)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

        case .automaticRewards:
            Text(Localization.stakingDetailsAutoClaimingRewardsDailyText)
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

        case .rewards(let fiatFormatted, let cryptoFormatted, let action):
            Button(action: action) {
                HStack(spacing: 4) {
                    Text(fiatFormatted)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                    Text(AppConstants.dotSign)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                    Text(cryptoFormatted)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)

                    Spacer(minLength: 12)

                    Assets.chevron.image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.informative)
                }
            }
        }
    }
}

#Preview("RewardView") {
    ZStack {
        Colors.Background.secondary.ignoresSafeArea()

        GroupedSection(
            [
                RewardViewData(state: .noRewards),
                RewardViewData(
                    state: .rewards(fiatFormatted: "24.12$", cryptoFormatted: "23.421 SOL", action: {})
                ),
            ]
        ) {
            RewardView(data: $0)
        }
        .interItemSpacing(12)
        .innerContentPadding(12)
        .padding()
    }
}
