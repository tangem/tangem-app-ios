//
//  TangemExchangeFactory.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import ExchangeSdk

/// Public factory for work with exchange
enum TangemExchangeFactory {
    static func createExchangeManager(
        source: Currency,
        destination: Currency?,
        blockchainProvider: BlockchainProvider,
        isDebug: Bool = false
    ) -> ExchangeManager {
        let exchangeItems = ExchangeItems(source: source, destination: destination)
        let exchangeService = ExchangeSdk.buildOneInchExchangeService(isDebug: isDebug)
        
        let provider = ExchangeOneInchProvider(blockchainProvider: blockchainProvider, exchangeService: exchangeService)
        return CommonExchangeManager(provider: provider, exchangeItems: exchangeItems)
    }
}
