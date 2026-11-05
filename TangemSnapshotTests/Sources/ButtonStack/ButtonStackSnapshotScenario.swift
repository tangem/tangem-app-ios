//
//  ButtonStackSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI

enum ButtonStackSnapshotScenario: String, SnapshotScenario {
    case amounts
    case labels
    case amountsRTL
    case labelsLargeText

    var layoutDirection: LayoutDirection {
        self == .amountsRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .labelsLargeText ? .xxxLarge : .large
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch self {
            case .amounts, .amountsRTL:
                ButtonStack(bell)
                ButtonStack(bell, search)
                ButtonStack(bell, search, more)
            case .labels, .labelsLargeText:
                ButtonStack(manage)
                ButtonStack(manage.iconStart(DesignSystem.Icons.Bell.regular20), search, more)
            }
        }
        .padding(16)
    }
}

@MainActor
private extension ButtonStackSnapshotScenario {
    var bell: TangemUI.Button {
        TangemUI.Button(icon: DesignSystem.Icons.Bell.regular20, accessibilityLabel: "Notifications", action: {})
    }

    var search: TangemUI.Button {
        TangemUI.Button(icon: DesignSystem.Icons.Search.regular20, accessibilityLabel: "Search", action: {})
    }

    var more: TangemUI.Button {
        TangemUI.Button(icon: DesignSystem.Icons.DotsVertical.regular20, accessibilityLabel: "More", action: {})
    }

    var manage: TangemUI.Button {
        TangemUI.Button(label: "Manage", accessibilityLabel: nil, action: {})
    }
}
