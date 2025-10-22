//
//  nftAccountNavigationContextProviderMock.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct nftAccountNavigationContextProviderMock: NFTAccountNavigationContextProviding {
    func provide(for accountID: AnyHashable) -> NFTNavigationContext? {
        nil
    }
}
