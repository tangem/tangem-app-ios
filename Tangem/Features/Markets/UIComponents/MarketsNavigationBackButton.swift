//
//  MarketsNavigationBackButton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemUI

struct MarketsNavigationBackButton: View {
    let presentSource: PresentSource
    let action: () -> Void

    var body: some View {
        redesignBody
    }

    // MARK: - Redesign

    @ViewBuilder
    private var redesignBody: some View {
        switch presentSource {
        case .navigation:
            redesignButton(icon: Assets.DesignSystem.chevronSmallLeft.image)
        case .deeplink:
            redesignButton(icon: Assets.DesignSystem.close.image)
        }
    }

    private func redesignButton(icon: Image) -> some View {
        Button(action: action) {
            icon
                .renderingMode(.template)
                .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)
        }
        .frame(width: 44, height: 44)
        .background(Color.Tangem.Button.backgroundSecondary, in: Circle())
        .padding(.leading, .unit(.x4))
    }
}

extension MarketsNavigationBackButton {
    enum PresentSource {
        case navigation
        case deeplink
    }
}
