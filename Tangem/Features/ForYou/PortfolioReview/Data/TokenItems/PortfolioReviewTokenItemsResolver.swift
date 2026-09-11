//
//  PortfolioReviewTokenItemsResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum PortfolioReviewTokenItemsResolver {
    /// A network with no derivation has no wallet model, so its entries stay `.withoutDerivation` instead of vanishing.
    static func resolve(userTokens: [TokenItem], walletModels: [any WalletModel]) -> [TokenItemType] {
        let walletModelsByID = walletModels.keyedFirst(by: \.id)
        let derivedNetworks = walletModels.map(\.tokenItem.blockchainNetwork).toSet()

        return userTokens.compactMap { userToken -> TokenItemType? in
            guard derivedNetworks.contains(userToken.blockchainNetwork) else {
                return .withoutDerivation(userToken)
            }

            return walletModelsByID[WalletModelId(tokenItem: userToken)].map { .default($0) }
        }
    }
}
