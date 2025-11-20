//
//  AccountIconViewBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts

enum AccountIconViewBuilder {
    static func makeAccountIconViewData(accountModel: any BaseAccountModel) -> AccountIconView.ViewData {
        let nameMode = AccountModelUtils.UI.nameMode(
            from: accountModel.icon.name,
            accountName: accountModel.name
        )

        let backgroundColor = AccountModelUtils.UI.iconColor(from: accountModel.icon.color)
        return .init(backgroundColor: backgroundColor, nameMode: nameMode)
    }
}
