//
//  Currency+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExchange

protocol CurrencyMapping {
    func mapToCurrency(token: Token, blockchain: Blockchain) -> Currency?
    func mapToCurrency(blockchain: Blockchain) -> Currency?
    func mapToCurrency(coinModel: CoinModel) -> Currency?

    func mapToToken(currency: Currency) -> Token?
}

struct CurrencyMapper: CurrencyMapping {
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
            supportOptions: [.eip2612],
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
            supportOptions: [],
            currencyType: .coin
        )
    }

    func mapToCurrency(coinModel: CoinModel) -> Currency? {
        let coinType = coinModel.items.first

        switch coinType {
        case .blockchain(let blockchain):
            return mapToCurrency(blockchain: blockchain)
        case .token(let token, let blockchain):
            return mapToCurrency(token: token, blockchain: blockchain)
        case .none:
            assertionFailure("CoinModel haven't items")
            return nil
        }
    }

    func mapToToken(currency: Currency) -> Token? {
        guard let contractAddress = currency.contractAddress else {
            return nil
        }

        return Token(
            name: currency.name,
            symbol: currency.symbol,
            contractAddress: contractAddress,
            decimalCount: currency.decimalCount,
            id: currency.id
        )
    }
}
