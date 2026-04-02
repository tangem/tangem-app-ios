//
//  UserTokensReorderingOptionsConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct UserTokensReorderingOptionsConverter {
    func convert(
        _ groupType: StoredCryptoAccount.Grouping
    ) -> UserTokensReorderingOptions.Grouping {
        switch groupType {
        case .none:
            return .none
        case .byBlockchainNetwork:
            return .byBlockchainNetwork
        }
    }

    func convert(
        _ sortType: StoredCryptoAccount.Sorting
    ) -> UserTokensReorderingOptions.Sorting {
        switch sortType {
        case .manual:
            return .dragAndDrop
        case .byBalance:
            return .byBalance
        }
    }

    func convert(
        _ groupType: UserTokensReorderingOptions.Grouping
    ) -> StoredCryptoAccount.Grouping {
        switch groupType {
        case .none:
            return .none
        case .byBlockchainNetwork:
            return .byBlockchainNetwork
        }
    }

    func convert(
        _ sortType: UserTokensReorderingOptions.Sorting
    ) -> StoredCryptoAccount.Sorting {
        switch sortType {
        case .dragAndDrop:
            return .manual
        case .byBalance:
            return .byBalance
        }
    }
}
