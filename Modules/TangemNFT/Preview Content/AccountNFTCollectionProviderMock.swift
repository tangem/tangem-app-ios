//
//  AccountNFTCollectionProviderMock.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct AccountNFTCollectionProviderMock: AccountForNFTCollectionsProviding {
    func provideAccountsWithCollectionsState(for collections: [NFTCollection]) -> AccountsWithCollectionsState {
        .singleAccount(NFTNavigationContextMock())
    }
}
