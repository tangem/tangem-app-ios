//
//  AccountForNFTData.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts
import Foundation

public struct AccountForNFTData {
    let iconData: AccountIconView.ViewData
    let name: String
    let id: AnyHashable

    public init(id: AnyHashable, iconData: AccountIconView.ViewData, name: String) {
        self.id = id
        self.iconData = iconData
        self.name = name
    }
}

public struct AccountWithCollectionsData {
    let accountData: AccountForNFTData
    let navigationContext: NFTNavigationContext
    let collections: [NFTCollection]

    public init(
        accountData: AccountForNFTData,
        collections: [NFTCollection],
        navigationContext: NFTNavigationContext
    ) {
        self.accountData = accountData
        self.collections = collections
        self.navigationContext = navigationContext
    }
}

public enum AccountsWithCollectionsState {
    case singleAccount(NFTNavigationContext)
    case multipleAccounts([AccountWithCollectionsData])
}
