//
//  ActionMessageSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI

enum ActionMessageSnapshotScenario: String, SnapshotScenario {
    case variants
    case variantsRTL
    case truncation
    case variantsLargeText

    var layoutDirection: LayoutDirection {
        self == .variantsRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .variantsLargeText ? .accessibility2 : .large
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        switch self {
        case .variants, .variantsRTL, .variantsLargeText:
            messages(text: "Invite members to join")
                .frame(width: 320)
        case .truncation:
            messages(text: "Your card backup is not finished yet. Complete it to protect your funds")
                .frame(width: 240)
        }
    }
}

@MainActor
private extension ActionMessageSnapshotScenario {
    func messages(text: String) -> some View {
        VStack(spacing: 8) {
            ForEach(ActionMessageVariant.allCases, id: \.self) { variant in
                ActionMessage(text, icon: DesignSystem.Icons.UserPlus.regular16) {}
                    .variant(variant)
            }
        }
    }
}
