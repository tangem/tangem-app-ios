//
//  ExpressInteractorDestinationWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress
import TangemFoundation

protocol ExpressInteractorDestinationWallet: ExpressDestinationWallet {
    var id: WalletModelId { get }
    var userWalletId: UserWalletId { get }
    var tokenItem: TokenItem { get }
    var isCustom: Bool { get }
    var isNewlyAddedFromMarkets: Bool { get }
    var tokenHeader: ExpressInteractorTokenHeader? { get }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { get }
}

extension ExpressInteractorDestinationWallet {
    func transactionParams() throws -> (any TransactionParams)? {
        guard let extraId else {
            return nil
        }

        let builder = TransactionParamsBuilder(blockchain: tokenItem.blockchain)
        return try builder.transactionParameters(value: extraId)
    }
}

extension ExpressInteractorDestinationWallet {
    var isNewlyAddedFromMarkets: Bool { false }
}
