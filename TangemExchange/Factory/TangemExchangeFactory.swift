//
//  TangemExchangeFactory.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Public factory for work with exchange
public enum TangemExchangeFactory {
    public static func createExchangeManager<TxBuilder: TransactionBuilder>(
        transactionBuilder: TxBuilder,
        blockchainInfoProvider: BlockchainInfoProvider,
        source: Currency,
        destination: Currency?,
        amount: Decimal? = nil
    ) -> ExchangeManager {
        let exchangeItems = ExchangeItems(source: source, destination: destination)
        let exchangeService = OneInchAPIService()
        let provider = OneInchExchangeProvider(exchangeService: exchangeService)

        return DefaultExchangeManager(
            exchangeProvider: provider,
            transactionBuilder: transactionBuilder,
            blockchainInfoProvider: blockchainInfoProvider,
            exchangeItems: exchangeItems,
            amount: amount
        )
    }
}
