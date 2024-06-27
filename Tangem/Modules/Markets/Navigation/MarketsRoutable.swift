//
//  MarketsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsRoutable: AnyObject {
    func openAddCustomToken(dataSource: MarketsDataSource)

    func openTokenSelector(
        dataSource: MarketsDataSource,
        coinId: String,
        tokenItems: [TokenItem]
    )

    func showGenerateAddressesWarning(
        numberOfNetworks: Int,
        currentWalletNumber: Int,
        totalWalletNumber: Int,
        action: @escaping () -> Void
    )

    func hideGenerateAddressesWarning()

    func openFilterOrderBottonSheet(with provider: MarketsListDataFilterProvider)

    func openTokenMarketsDetails(for tokenInfo: MarketsTokenModel)
}
