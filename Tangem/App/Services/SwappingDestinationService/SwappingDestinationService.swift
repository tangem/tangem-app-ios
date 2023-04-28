//
//  SwappingDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSwapping

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

            for preferred in PreferredTokenSymbol.allCases {
                if let token = walletModel.getTokens().first(where: { $0.symbol == preferred.rawValue }) {
                    preferredToken = token
                    break
                }
            }

            if let preferredToken,
               let currency = mapper.mapToCurrency(token: preferredToken, blockchain: blockchain) {
                return currency
            }

            return try await loadPreferredCurrency(networkId: blockchain.networkId)
        }

        throw CommonError.noData
    }
}

private extension SwappingDestinationService {
    func loadPreferredCurrency(networkId: String) async throws -> Currency {
        for preferred in PreferredTokenSymbol.allCases {
            if let currency = try? await loadPreferredCurrencyFromAPI(networkId: networkId, tokenSymbol: preferred.rawValue) {
                return currency
            }
        }

        return try await loadPreferredCurrencyFromAPI(networkId: networkId)
    }

    func loadPreferredCurrencyFromAPI(networkId: String, tokenSymbol: String? = nil) async throws -> Currency {
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
    enum PreferredTokenSymbol: String, CaseIterable {
        case usdt = "USDT"
        case usdc = "USDC"
    }
}
