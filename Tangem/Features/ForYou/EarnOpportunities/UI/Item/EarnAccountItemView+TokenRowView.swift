//
//  EarnAccountItemView+TokenRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

extension EarnAccountItemView {
    struct TokenRowView: View {
        let data: EarnTokenRowData
        let onTap: () -> Void

        @ScaledMetric private var iconSize: CGFloat = 40

        var body: some View {
            Row(
                title: data.name,
                subtitle: data.network,
                subvalue: data.apyText
            )
            .valueAccessory { EarnAccountItemView.RewardText(amount: data.rewardAmount) }
            .overrideTextColors(.init(subvalue: DesignSystem.Color.textAccentGreen))
            .start { icon }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .accessibilityAddTraits(.isButton)
        }
    }
}

private extension EarnAccountItemView.TokenRowView {
    var icon: some View {
        TokenIcon(
            tokenIconInfo: data.tokenIconInfo,
            size: CGSize(bothDimensions: iconSize),
            isWithOverlays: true
        )
    }
}
