//
//  NFTAccountsProvider.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

public protocol AccountsAwareNFTManagersFacade {
    var collectionsPublisher: AnyPublisher<NFTPartialResult<[NFTCollection]>, Never> { get }
    var collections: [NFTCollection] { get }

    func updateInternal()

    /// Only needed until [REDACTED_INFO] is done
    var primaryNFTManager: NFTManager { get }
}

public enum AccountsWithNFTManagersState {
    case singleAccount(accountID: Hashable, NFTManager)
    case multipleAccounts([AccountsWithNFTManagersData])

    public var nftManagers: [NFTManager] {
        switch self {
        case .singleAccount(_, let nftManager):
            [nftManager]
        case .multipleAccounts(let accountsWithNFTManagersData):
            accountsWithNFTManagersData.map(\.nftManager)
        }
    }
}

public struct AccountsWithNFTManagersData {
    public let accountID: Hashable
    public let nftManager: any NFTManager

    public init(accountID: Hashable, nftManager: any NFTManager) {
        self.accountID = accountID
        self.nftManager = nftManager
    }
}
