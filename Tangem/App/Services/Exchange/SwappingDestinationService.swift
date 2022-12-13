//
//  SwappingDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange
import BlockchainSdk

protocol SwappingDestinationServicing {
    func getDestination(source: Currency) async throws -> Currency
}

struct SwappingDestinationService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let walletModel: WalletModel
    private let mapper: CurrencyMapping
    private let usdtTokenSymbol = "USDT"
    private let usdcTokenSymbol = "USDC"

    init(walletModel: WalletModel, mapper: CurrencyMapping) {
        self.walletModel = walletModel
        self.mapper = mapper
    }
}

// MARK: - SwappingDestinationServicing

extension SwappingDestinationService: SwappingDestinationServicing {
    func getDestination(source: Currency) async throws -> Currency {
        let blockchain = walletModel.blockchainNetwork.blockchain

        switch source.currencyType {
        case .token:
            if let currency = mapper.mapToCurrency(blockchain: blockchain) {
                return currency
            }

        case .coin:
            var preferToken: Token?

            for token in walletModel.getTokens() {
                if token.symbol == usdtTokenSymbol {
                    preferToken = token
                    break
                }

                if token.symbol == usdcTokenSymbol, preferToken == nil {
                    preferToken = token
                    break
                }
            }

            if let preferToken,
               let currency = mapper.mapToCurrency(token: preferToken, blockchain: blockchain) {
                return currency
            }

            return try await loadPreferCurrency(networkId: blockchain.networkId)
        }

        throw CommonError.noData
    }
}

private extension SwappingDestinationService {
    func loadPreferCurrency(networkId: String) async throws -> Currency {
        // Try to load USDT
        if let usdt = try? await loadPreferCurrencyFromAPI(networkId: networkId, tokenSymbol: usdtTokenSymbol) {
            return usdt
        }

        // Try to load USDC
        if let usdc = try? await loadPreferCurrencyFromAPI(networkId: networkId, tokenSymbol: usdcTokenSymbol) {
            return usdc
        }

        return try await loadPreferCurrencyFromAPI(networkId: networkId)
    }

    func loadPreferCurrencyFromAPI(networkId: String, tokenSymbol: String? = nil) async throws -> Currency {
        let model = CoinsListRequestModel(
            networkIds: [networkId],
            searchText: tokenSymbol,
            exchangeable: true
        )

        let coins = try await tangemApiService.loadCoins(requestModel: model).async()
        let coin: CoinModel?

        /// If we are founding special token by name
        if let tokenSymbol = tokenSymbol {
            coin = coins.first(where: { $0.symbol == tokenSymbol })
        } else {
            coin = coins.first
        }

        if let coin, let currency = mapper.mapToCurrency(coinModel: coin) {
            return currency
        }

        throw CommonError.noData
    }
}
