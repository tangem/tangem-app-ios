//
//  AddFundsTokenInfoView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemUI

struct AddFundsTokenInfoView: View {
    let viewData: ViewData

    var body: some View {
        VStack(spacing: 12) {
            TokenIcon(tokenIconInfo: viewData.tokenIconInfo, size: CGSize(width: 64, height: 64))

            VStack(spacing: 4) {
                Text(viewData.fiatBalance)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(viewData.cryptoBalance)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }

            AccountInlineHeaderView(iconData: viewData.accountBadge.iconData, name: viewData.accountBadge.name)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Colors.Background.action)
                )
        }
        .infinityFrame(axis: .horizontal)
    }
}

extension AddFundsTokenInfoView {
    struct ViewData: Hashable {
        let tokenIconInfo: TokenIconInfo
        let fiatBalance: String
        let cryptoBalance: String
        let accountBadge: AccountBadge
    }

    struct AccountBadge: Hashable {
        let iconData: AccountIconView.ViewData
        let name: String
    }
}
