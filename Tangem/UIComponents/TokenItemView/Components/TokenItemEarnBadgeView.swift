//
//  TokenItemEarnBadgeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemAccessibilityIdentifiers
import TangemLocalization
import TangemStaking

struct TokenItemEarnBadgeView: View {
    let rewardType: RewardType
    let rewardValue: String
    let color: Color
    let tapAction: (() -> Void)?
    let isUpdating: Bool

    private var background: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous).fill(color.opacity(0.1))
    }

    var body: some View {
        if let tapAction {
            Button(action: tapAction) {
                mainContent
            }
        } else {
            mainContent
        }
    }

    // MARK: - Sub Views

    private var mainContent: some View {
        HStack(spacing: 6) {
            Text("\(rewardTypeString) \(rewardValue)")
                .style(Fonts.BoldStatic.caption2, color: color)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier(MainAccessibilityIdentifiers.tokenItemEarnBadge)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(background)
                .shimmer()
        }
        .onTapGesture {
            tapAction?()
        }
        .environment(\.isShimmerActive, isUpdating)
    }

    var rewardTypeString: String {
        switch rewardType {
        case .apr: Localization.stakingDetailsApr
        case .apy: Localization.stakingDetailsApy
        }
    }
}
