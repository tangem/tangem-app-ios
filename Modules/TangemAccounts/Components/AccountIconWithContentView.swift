//
//  AccountIconWithContentView.swift
//  TangemAccounts
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

public struct AccountIconWithContentView<Subtitle: View, Trailing: View>: View {
    let iconData: AccountIconView.ViewData
    let name: String
    let subtitle: Subtitle
    let trailing: Trailing

    public init(
        iconData: AccountIconView.ViewData,
        name: String,
        @ViewBuilder subtitle: () -> Subtitle,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.iconData = iconData
        self.name = name
        self.subtitle = subtitle()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 0) {
            AccountIconView(data: iconData)
                .padding(.trailing, 12)

            contentStack
                .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 8)

            trailing
        }
        .contentShape(Rectangle())
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .lineLimit(1)

            subtitle
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .lineLimit(1)
        }
    }
}

// MARK: - Default Empty Trailing

public extension AccountIconWithContentView where Trailing == EmptyView {
    init(
        iconData: AccountIconView.ViewData,
        name: String,
        @ViewBuilder subtitle: () -> Subtitle
    ) {
        self.iconData = iconData
        self.name = name
        self.subtitle = subtitle()
        trailing = EmptyView()
    }
}
