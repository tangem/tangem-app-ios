//
//  AccountProviderForNFTCollection.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT

final class AccountForNFTCollectionProvider {
    private let accountModelsManager: AccountModelsManager

    init(accountModelsManager: AccountModelsManager) {
        self.accountModelsManager = accountModelsManager
    }
}

extension AccountForNFTCollectionProvider: AccountForNFTCollectionProviding {
    func provideAccountsWithCollectionsState(for collections: [NFTCollection]) -> AccountsWithCollectionsState {
        // [REDACTED_TODO_COMMENT]
        // For now returning a stub
        return .singleAccount
    }
}
