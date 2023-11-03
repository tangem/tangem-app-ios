//
//  UserCurrenciesProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSwapping
import Combine
import BlockchainSdk

struct UserCurrenciesProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let blockchain: Blockchain
    private let walletModelTokens: [Token]
    private let currencyMapper: CurrencyMapping

    init(blockchain: Blockchain, walletModelTokens: [Token], currencyMapper: CurrencyMapping) {
        self.blockchain = blockchain
        self.walletModelTokens = walletModelTokens
        self.currencyMapper = currencyMapper
    }
}

// MARK: - UserCurrenciesProviding

extension UserCurrenciesProvider: UserCurrenciesProviding {
    func getCurrencies(blockchain swappingBlockchain: SwappingBlockchain) async -> [Currency] {
        var currencies: [Currency] = []
        if let coinCurrency = currencyMapper.mapToCurrency(blockchain: blockchain) {
            currencies.append(coinCurrency)
        }

        let tokenIds = walletModelTokens.compactMap(\.id)
        if tokenIds.isEmpty {
            return currencies
        }

        // Get user tokens from API with filled in fields
        // For checking exchangeable
        do {
            let tokens = try await filterTokens(with: tokenIds, in: blockchain)
            currencies += tokens.compactMap { token in
                currencyMapper.mapToCurrency(token: token, blockchain: blockchain)
            }
        } catch {
            AppLog.shared.debug("UserCurrenciesProvider could not loaded tokens")
            AppLog.shared.error(error)
        }

        return currencies
    }
}

private extension UserCurrenciesProvider {
    func filterTokens(with ids: [String], in blockchain: Blockchain) async throws -> [Token] {
        let request = CoinsList.Request(supportedBlockchains: [blockchain], ids: ids)
        let coins = try await tangemApiService.loadCoins(requestModel: request).async()

        let tokens = coins.compactMap { coin -> Token? in
            guard let item = coin.items.first(where: { $0.id == coin.id }), item.exchangeable else {
                return nil
            }

            return item.tokenItem.token
        }

        return tokens
    }
}
