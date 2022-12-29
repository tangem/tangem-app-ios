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
        permitTypedDataProvider: PermitTypedDataProviding,
        source: Currency,
        destination: Currency?,
        amount: Decimal? = nil
    ) -> ExchangeManager {
        let exchangeItems = ExchangeItems(source: source, destination: destination, supportedPermit: true, permit: nil)
        let exchangeService = OneInchAPIService()
        let provider = OneInchExchangeProvider(exchangeService: exchangeService)

        return DefaultExchangeManager(
            exchangeProvider: provider,
            blockchainInfoProvider: blockchainInfoProvider,
            permitTypedDataProvider: permitTypedDataProvider,
            exchangeItems: exchangeItems,
            amount: amount
        )
    }
}
