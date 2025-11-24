//
//  AccountWithCollectionsData.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAccounts

struct AccountWithCollectionViewModels {
    let accountData: AccountData
    let collectionsViewModels: [NFTCollectionDisclosureGroupViewModel]

    func withUpdatedCollections(_ collections: [NFTCollectionDisclosureGroupViewModel]) -> Self {
        AccountWithCollectionViewModels(
            accountData: accountData,
            collectionsViewModels: collections
        )
    }
}

extension AccountWithCollectionViewModels {
    struct AccountData {
        let id: AnyHashable
        let name: String
        let iconData: AccountIconView.ViewData
    }
}
