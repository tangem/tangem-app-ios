//
//  InfoRowWithAction.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct InfoRowWithAction<Icon: View>: View {
    private let icon: Icon
    private let title: String
    private let value: String
    private let actionTitle: String
    private let onAction: () -> Void

    public init(
        @ViewBuilder icon: () -> Icon,
        title: String,
        value: String,
        actionTitle: String,
        onAction: @escaping () -> Void
    ) {
        self.icon = icon()
        self.title = title
        self.value = value
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    public var body: some View {
        RowWithLeadingAndTrailingIcons(
            leadingIcon: {
                icon
            },
            content: {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(title)
                        .style(Fonts.Regular.caption1, color: DesignSystem.Color.textSecondary)

                    Text(value)
                        .style(Fonts.Bold.subheadline, color: DesignSystem.Color.textPrimary)
                }
            },
            trailingIcon: {
                CapsuleButton(title: actionTitle, action: onAction)
            }
        )
    }
}
