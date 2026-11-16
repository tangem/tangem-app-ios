//
//  EthEarnBannerSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
@testable import Tangem

enum EthEarnBannerSnapshotScenario: String, SnapshotScenario {
    case earnBanner
    case earnBannerLargeText
    case earnBannerRightToLeft

    var dynamicTypeSize: DynamicTypeSize {
        self == .earnBannerLargeText ? .xxxLarge : .large
    }

    var layoutDirection: LayoutDirection {
        self == .earnBannerRightToLeft ? .rightToLeft : .leftToRight
    }

    @MainActor
    var body: some View {
        TokenDetailsStakingView(state: .earn(item: .init(
            title: "Earn",
            description: "Up to 3.1% APY",
            actionTitle: "Enable",
            action: {}
        )))
        .frame(width: 370)
        .environment(\._accessibilityReduceMotion, true)
    }
}
