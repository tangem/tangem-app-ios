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
                // [REDACTED_TODO_COMMENT]
                .collectiblesDevnetAlert(viewModel.devnet)
        }
    }
}

// MARK: - ActionsMenu + Content

private extension ActionsMenu {
    @ViewBuilder
    var items: some View {
        // [REDACTED_TODO_COMMENT]
        SwiftUI.Button {} label: {
            Label(
                title: { Text(Localization.collectiblesMainMenuActivityLog) },
                icon: { DesignSystem.Icons.Clock.regular20.image.renderingMode(.template) }
            )
        }

        SwiftUI.Button {} label: {
            Label(
                title: { Text(Localization.collectiblesMainMenuDeliveries) },
                icon: { DesignSystem.Icons.Globe.regular20.image.renderingMode(.template) }
            )
        }

        Divider()

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

        // [REDACTED_TODO_COMMENT]
        CollectiblesDevnetMenu(viewModel: viewModel.devnet)
    }

    var trigger: some View {
        DesignSystem.Icons.DotsVertical.regular20.image
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .frame(size: CGSize(bothDimensions: Metrics.iconSide))
            .contentShape(.rect)
    }
}

// MARK: - Metrics

private extension ActionsMenu {
    enum Metrics {
        static let iconSide: CGFloat = 20
    }
}

// MARK: - Previews

#Preview {
    CollectiblesMainView.ActionsMenu(viewModel: CollectiblesActionsMenuViewModel(routable: nil))
}
