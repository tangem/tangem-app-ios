//
//  AccountIconWithContentView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccounts

struct AccountIconWithContentView<Subtitle: View, Trailing: View>: View {
    let iconData: AccountIconView.ViewData
    let name: String
    let subtitle: Subtitle
    let trailing: Trailing

    init(
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

    var body: some View {
        HStack(spacing: 12) {
            AccountIconView(data: iconData)

            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                subtitle
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
            .frame(alignment: .leading)

            Spacer()

            trailing
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Default Empty Trailing

extension AccountIconWithContentView where Trailing == EmptyView {
    init(
        iconData: AccountIconView.ViewData,
        name: String,
        @ViewBuilder subtitle: () -> Subtitle
    ) {
        self.iconData = iconData
        self.name = name
        self.subtitle = subtitle()
        self.trailing = EmptyView()
    }
}
