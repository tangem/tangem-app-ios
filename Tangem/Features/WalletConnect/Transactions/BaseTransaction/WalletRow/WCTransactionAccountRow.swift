//
//  WCTransactionAccountRow.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI

struct WCTransactionAccountRow: View {
    let viewState: ViewState

    var body: some View {
        BaseOneLineRow(icon: Assets.Glyphs.walletNew, title: Localization.accountDetailsTitle) {
            HStack(spacing: 6) {
                AccountIconView(
                    data: AccountModelUtils.UI.iconViewData(
                        icon: viewState.accountIcon,
                        accountName: viewState.accountName
                    )
                )
                .settings(.smallSized)

                Text(viewState.accountName)
                    .style(Fonts.Regular.body, color: Colors.Text.tertiary)
            }
        }
        .shouldShowTrailingIcon(false)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }
}

extension WCTransactionAccountRow {
    struct ViewState {
        let accountName: String
        let accountIcon: AccountModel.Icon
    }
}
