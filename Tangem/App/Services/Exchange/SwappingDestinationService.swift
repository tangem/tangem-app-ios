//
//  SwappingDestinationService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

protocol SwappingDestinationServing {
    func getDestination(source: Currency) async throws -> Currency
}

struct SwappingDestinationService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    
    private let walletModel: WalletModel
    private let preferTokens = ["USDT", "USDC"]
    
    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

extension SwappingDestinationService: SwappingDestinationServing {
    func getDestination(source: Currency) async throws -> Currency {
        let savedUserToken = walletModel.getTokens().first { token in
            preferTokens.contains { $0 == token.id }
        }
        
        if let savedUserToken {
            return source // Mapping
        }
        
        let model = CoinsListRequestModel(networkIds: [source.blockchain.networkId])
        let coins = try await tangemApiService  .loadCoins(requestModel: model).async()
        
        let preferCoin = coins.first { coin in
            preferTokens.contains { $0 == coin.id }
        }
        
        if let preferCoin {
            return source // Mapping
        }
        
        throw CommonError.noData
    }
}
