//
//  Currency+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExchange

struct CurrencyMapper {
    func mapToCurrency(token: Token, blockchain: Blockchain) -> Currency? {
        guard let exchangeBlockchain = ExchangeBlockchain(networkId: blockchain.networkId) else {
            assertionFailure("ExchangeBlockchain don't support")
            return nil
        }

        guard let id = token.id else {
            assertionFailure("Token not have id")
            return nil
        }

        return Currency(
            id: id,
            blockchain: exchangeBlockchain,
            name: token.name,
            symbol: token.symbol,
            decimalCount: token.decimalCount,
            currencyType: .token(contractAddress: token.contractAddress)
        )
    }

    func mapToCurrency(blockchain: Blockchain) -> Currency? {
        guard let exchangeBlockchain = ExchangeBlockchain(networkId: blockchain.networkId) else {
            assertionFailure("ExchangeBlockchain don't support")
            return nil
        }

        return Currency(
            id: blockchain.id,
            blockchain: exchangeBlockchain,
            name: blockchain.displayName,
            symbol: blockchain.currencySymbol,
            decimalCount: blockchain.decimalCount,
            currencyType: .coin
        )
    }
}
