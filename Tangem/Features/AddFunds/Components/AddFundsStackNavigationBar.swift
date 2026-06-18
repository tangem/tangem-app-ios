//
//  AddFundsStackNavigationBar.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemUI

struct AddFundsStackNavigationBar: View {
    let title: String
    let accountBadge: AddFundsTokenInfoView.AccountBadge?
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .center) {
            HStack(spacing: .zero) {
                Spacer()
                NavigationBarButton.close(action: onClose)
            }

            VStack(spacing: 2) {
                Text(title)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
                    .lineLimit(1)

                if let accountBadge {
                    AccountInlineHeaderView(iconData: accountBadge.iconData, name: accountBadge.name)
                        .font(Fonts.Regular.caption1)
                        .textColor(Colors.Text.tertiary)
                }
            }
        }
        .infinityFrame(axis: .horizontal)
        .padding(.vertical, 12)
    }
}
