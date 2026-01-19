//
//  GetTokenActionRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct GetTokenActionRowView: View {
    let icon: ImageType
    let title: String
    let subtitle: String?
    let showNotificationBadge: Bool
    let style: Style

    init(
        icon: ImageType,
        title: String,
        subtitle: String? = nil,
        showNotificationBadge: Bool = false,
        style: Style = .colored(Colors.Icon.accent)
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showNotificationBadge = showNotificationBadge
        self.style = style
    }

    var body: some View {
        HStack(spacing: style.horizontalSpacing) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                if let subtitle {
                    Text(subtitle)
                        .multilineTextAlignment(.leading)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var iconView: some View {
        let iconImage = icon.image
            .renderingMode(.template)
            .frame(width: 20, height: 20)

        switch style {
        case .colored(let color):
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                iconImage
                    .foregroundColor(color)
            }
            .unreadNotificationBadge(showNotificationBadge, badgeColor: Colors.Icon.accent)

        case .solid:
            iconImage
                .foregroundStyle(Colors.Icon.primary1)
                .padding(10)
                .background(
                    Circle()
                        .fill(Colors.Background.tertiary)
                )
                .padding(.leading, 2)
                .unreadNotificationBadge(showNotificationBadge, badgeColor: Colors.Icon.accent)
        }
    }
}

// MARK: - Style

extension GetTokenActionRowView {
    enum Style {
        case colored(Color)
        case solid

        var horizontalSpacing: CGFloat {
            switch self {
            case .colored:
                return 12
            case .solid:
                return 16
            }
        }
    }
}
