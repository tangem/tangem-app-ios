//
//  PolymarketOverflowMenu.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct PolymarketOverflowMenu: View {
    let onHowItWorks: () -> Void
    let onSupportChat: () -> Void

    var body: some View {
        Menu {
            SwiftUI.Button(action: onHowItWorks) {
                Label(
                    title: { Text(Constants.howItWorksTitle) },
                    icon: { DesignSystem.Icons.Info.regular20.image.renderingMode(.template) }
                )
            }

            SwiftUI.Button(action: onSupportChat) {
                Label(
                    title: { Text(Constants.supportChatTitle) },
                    icon: { DesignSystem.Icons.HeadphonesSupport.regular20.image.renderingMode(.template) }
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
        static let howItWorksTitle = Localization.collectiblesMainMenuHowItWorks
        static let supportChatTitle = Localization.supportChatScreenTitle
    }
}
