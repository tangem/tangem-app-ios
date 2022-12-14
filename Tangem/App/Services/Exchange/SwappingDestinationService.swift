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
            var preferredToken: Token?

            if let firstPreferred = walletModel.getTokens().first(where: { $0.symbol == PreferredToken.first.tokenSymbol }) {
                preferredToken = firstPreferred
            } else if let secondPreferred = walletModel.getTokens().first(where: { $0.symbol == PreferredToken.second.tokenSymbol }) {
                preferredToken = secondPreferred
            }

            if let preferredToken,
               let currency = mapper.mapToCurrency(token: preferredToken, blockchain: blockchain) {
                return currency
            }

            return try await loadPreferCurrency(networkId: blockchain.networkId)
        }

        throw CommonError.noData
    }
}

private extension SwappingDestinationService {
    func loadPreferCurrency(networkId: String) async throws -> Currency {
        if let firstPreferred = try? await loadPreferCurrencyFromAPI(networkId: networkId, tokenSymbol: PreferredToken.first.tokenSymbol) {
            return firstPreferred
        }

        if let secondPreferred = try? await loadPreferCurrencyFromAPI(networkId: networkId, tokenSymbol: PreferredToken.second.tokenSymbol) {
            return secondPreferred
        }

        return try await loadPreferCurrencyFromAPI(networkId: networkId)
    }

    func loadPreferCurrencyFromAPI(networkId: String, tokenSymbol: String? = nil) async throws -> Currency {
        let model = CoinsListRequestModel(
            networkIds: [networkId],
            searchText: tokenSymbol,
            exchangeable: true
        )

        let coinModels = try await tangemApiService.loadCoins(requestModel: model).async()
        let coinModel: CoinModel?

        /// If we are founding special token by name
        if let tokenSymbol = tokenSymbol {
            coinModel = coinModels.first(where: { $0.symbol == tokenSymbol })
        } else {
            coinModel = coinModels.first
        }

        if let coinModel, let currency = mapper.mapToCurrency(coinModel: coinModel) {
            return currency
        }

        throw CommonError.noData
    }
}

extension SwappingDestinationService {
    enum PreferredToken {
        case first
        case second
        
        var tokenSymbol: String {
            switch self {
            case .first:
                return "USDT"
            case .second:
                return "USDC"
            }
        }
    }
}
