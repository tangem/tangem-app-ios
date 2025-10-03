//
//  AccountsAwareNFTManagersFacade.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class AccountsAwareNFTManagersFacadeMock: AccountsAwareNFTManagersFacade {
    private let nftManager: NFTManager

    init(nftManager: NFTManager) {
        self.nftManager = nftManager
    }

    var collectionsPublisher: AnyPublisher<NFTPartialResult<[NFTCollection]>, Never> {
        nftManager.collectionsPublisher
    }

    var collections: [NFTCollection] {
        nftManager.collections
    }

    var primaryNFTManager: any NFTManager {
        nftManager
    }

    func updateInternal() {
        nftManager.update(cachePolicy: .always)
    }
}
