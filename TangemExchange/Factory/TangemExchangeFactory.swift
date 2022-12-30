//
//  TangemExchangeFactory.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Public factory for work with exchange
public struct TangemExchangeFactory {
    public init() {}

    public func createExchangeManager(
        blockchainInfoProvider: BlockchainDataProvider,
        source: Currency,
        destination: Currency?,
        amount: Decimal? = nil,
        logger: ExchangeLogger? = nil
    ) -> ExchangeManager {
        let exchangeItems = ExchangeItems(source: source, destination: destination)
        let exchangeService = OneInchAPIService(logger: logger ?? DefaultExchangeLogger())
        let provider = OneInchExchangeProvider(exchangeService: exchangeService)

        return DefaultExchangeManager(
            exchangeProvider: provider,
            blockchainInfoProvider: blockchainInfoProvider,
            exchangeItems: exchangeItems,
            amount: amount
        )
    }
}
