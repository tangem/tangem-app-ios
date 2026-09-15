//
//  PolymarketOverflowMenu.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PolymarketOverflowMenu: View {
    let onHowItWorks: () -> Void

    var body: some View {
        Menu {
            SwiftUI.Button(action: onHowItWorks) {
                Label(
                    title: { Text(Constants.howItWorksTitle) },
                    icon: { DesignSystem.Icons.Info.regular20.image.renderingMode(.template) }
                )
            }
        } label: {
            NavigationBarButton.details {}
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Constants

private extension PolymarketOverflowMenu {
    enum Constants {
        static let howItWorksTitle = "How it works"
    }
}
