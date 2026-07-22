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

        @ScaledMetric private var iconSize: CGFloat = 40

        var body: some View {
            Row(
                title: data.name,
                subtitle: data.network,
                value: data.rewardText,
                subvalue: data.apyPercent
            )
            .overrideTextColors(.init(subvalue: DesignSystem.Color.textAccentGreen))
            .start { icon }
            .includeInnerPadding(false)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

private extension EarnAccountItemView.TokenRowView {
    // [REDACTED_TODO_COMMENT]
    var icon: some View {
        Circle()
            .fill(DesignSystem.Color.bgTertiary)
            .frame(width: iconSize, height: iconSize)
    }
}
