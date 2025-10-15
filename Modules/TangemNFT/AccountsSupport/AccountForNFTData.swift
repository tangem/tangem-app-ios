//
//  AccountForNFTData.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts
import Foundation

/// Data is not final, perhaps we will need smt else ([REDACTED_INFO])
public struct AccountForNFTData {
    let iconData: AccountIconView.ViewData
    let name: String

    public init(iconData: AccountIconView.ViewData, name: String) {
        self.iconData = iconData
        self.name = name
    }
}

public struct AccountWithCollectionsData {
    let accountData: AccountForNFTData
    let collections: [NFTCollection]
}

public enum AccountsWithCollectionsState {
    case singleAccount
    case multipleAccounts([AccountWithCollectionsData])
}
