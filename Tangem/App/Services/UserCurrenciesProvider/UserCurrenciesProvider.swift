//
//  UserCurrenciesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

struct UserCurrenciesProvider {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - UserCurrenciesProviding

extension UserCurrenciesProvider: UserCurrenciesProviding {
    func getCurrencies(blockchain exchangeBlockchain: ExchangeBlockchain) -> [Currency] {
        let blockchain = walletModel.blockchainNetwork.blockchain

        guard blockchain.networkId == exchangeBlockchain.networkId else {
            assertionFailure("incorrect blockchain in WalletModel")
            return []
        }

        let mapper = CurrencyMapper()
        var currencies: [Currency] = []
        if let coinCurrency = mapper.mapToCurrency(blockchain: blockchain) {
            currencies.append(coinCurrency)
        }

        currencies += walletModel.getTokens().compactMap {
            mapper.mapToCurrency(token: $0, blockchain: blockchain)
        }

        return currencies
    }
}
