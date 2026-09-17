//
//  CollectiblesMainView+ActionsMenu.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

private typealias ActionsMenu = CollectiblesMainView.ActionsMenu

extension CollectiblesMainView {
    struct ActionsMenu: View {
        let viewModel: CollectiblesActionsMenuViewModel

        var body: some View {
            Menu(content: { items }, label: { trigger })
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(Localization.commonMore)
        }
    }
}

// MARK: - ActionsMenu + Content

private extension ActionsMenu {
    @ViewBuilder
    var items: some View {
        SwiftUI.Button(action: viewModel.onHowItWorksTap) {
            Label(
                title: { Text(Localization.collectiblesMainMenuHowItWorks) },
                icon: { DesignSystem.Icons.Info.regular20.image.renderingMode(.template) }
            )
        }

        SwiftUI.Button(action: viewModel.onSupportTap) {
            Label(
                title: { Text(Localization.collectiblesMainMenuGetAssistance) },
                icon: { DesignSystem.Icons.Mail.regular20.image.renderingMode(.template) }
            )
        }
    }

    var trigger: some View {
        NavigationBarButton.details(action: {})
            .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview {
    CollectiblesMainView.ActionsMenu(viewModel: CollectiblesActionsMenuViewModel(routable: nil))
}
