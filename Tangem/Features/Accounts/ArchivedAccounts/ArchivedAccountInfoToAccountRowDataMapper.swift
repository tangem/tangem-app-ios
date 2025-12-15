//
//  ArchivedAccountInfoToAccountRowDataMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization

enum ArchivedAccountInfoToAccountRowDataMapper {
    static func map(_ info: ArchivedCryptoAccountInfo) -> AccountRowViewModel.Input {
        AccountRowViewModel.Input(
            iconData: AccountModelUtils.UI.iconViewData(icon: info.icon, accountName: info.name),
            name: info.name,
            subtitle: Localization.commonTokensCount(info.tokensCount),
            availability: .available
        )
    }
}
