//
//  GachaMainView+ActionsMenu.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

extension GachaMainView {
    struct ActionsMenu: View {
        let onSelect: (Action) -> Void

        var body: some View {
            Menu {
                menuItem(.activityLog)
                menuItem(.deliveries)

                Divider()

                menuItem(.howItWorks)
                menuItem(.getAssistance)
            } label: {
                label
            }
            .tangemMaterialSurface(in: Circle(), interactive: true, shadow: DesignSystem.Shadow.fallbackButton)
            .accessibilityLabel(Localization.commonMore)
        }
    }
}

private extension GachaMainView.ActionsMenu {
    // MARK: - View properties

    var label: some View {
        DesignSystem.Icons.DotsVertical.regular20.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
            .frame(size: .init(bothDimensions: 44))
            .contentShape(Circle())
    }

    func menuItem(_ action: Action) -> some View {
        SwiftUI.Button {
            onSelect(action)
        } label: {
            Label(
                title: { Text(action.title) },
                icon: { action.icon.image.renderingMode(.template) }
            )
        }
    }
}

// MARK: - Action

extension GachaMainView.ActionsMenu {
    enum Action {
        case activityLog
        case deliveries
        case howItWorks
        case getAssistance

        var title: String {
            // [REDACTED_TODO_COMMENT]
            switch self {
            case .activityLog:
                "Activity log"
            case .deliveries:
                "Deliveries"
            case .howItWorks:
                "How it works"
            case .getAssistance:
                "Get assistance"
            }
        }

        var icon: ImageType {
            switch self {
            case .activityLog:
                DesignSystem.Icons.Clock.regular20
            case .deliveries:
                DesignSystem.Icons.Globe.regular20
            case .howItWorks:
                DesignSystem.Icons.Info.regular20
            case .getAssistance:
                DesignSystem.Icons.Mail.regular20
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary.ignoresSafeArea()

        GachaMainView.ActionsMenu(onSelect: { _ in })
    }
}
