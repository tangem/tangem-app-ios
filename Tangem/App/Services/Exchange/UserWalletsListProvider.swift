//
//  UserWalletsListProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

struct UserWalletsListProvider {
    private let walletModel: WalletModel

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

extension UserWalletsListProvider: UserWalletsListProviding {
    func saveCurrencyInUserList(currency: TangemExchange.Currency) {
        // [REDACTED_TODO_COMMENT]
    }

    func getUserCurrencies(blockchain: ExchangeBlockchain) -> [Currency] {
        let blockchain = walletModel.blockchainNetwork.blockchain

        guard blockchain.codingKey == blockchain.networkId else {
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
