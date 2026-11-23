//
//  LendingNoticeBanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct LendingNoticeBanner: View {
    let text: String

    var body: some View {
        MessageBanner(title: text)
            .glowRing(.info)
            .titleLineLimit(nil)
            .slotEnd {
                DesignSystem.Icons.Clock.regular20.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconPrimary)
                    .accessibilityHidden(true)
            }
    }
}
