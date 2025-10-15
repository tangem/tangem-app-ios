//
//  AccountForNFTCollectionProviding.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol AccountForNFTCollectionProviding {
    func provideAccountsWithCollectionsState(for collections: [NFTCollection]) -> AccountsWithCollectionsState
}
