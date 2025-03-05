//
//  MoralisNetworkResult.EVMNFTPrices.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkResult {
    struct EVMNFTPrices: Decodable {
        let lastSale: Sale?
        let lowestSale: Sale?
        let highestSale: Sale?
        let averageSale: AverageSale?
        let totalTrades: Int
    }
}

// MARK: - Nested DTOs

extension MoralisNetworkResult.EVMNFTPrices {
    struct Sale: Decodable {
        let transactionHash: String
        let blockTimestamp: String
        let buyerAddress: String
        let sellerAddress: String
        let price: String
        let priceFormatted: String
        let usdPriceAtSale: String
        let currentUSDValue: String // [REDACTED_TODO_COMMENT]
        let tokenId: String
        let paymentToken: PaymentToken
    }

    struct AverageSale: Decodable {
        let price: String
        let priceFormatted: String
        let currentUSDValue: String // [REDACTED_TODO_COMMENT]
    }

    struct PaymentToken: Decodable {
        let tokenName: String
        let tokenSymbol: String
        let tokenLogo: String
        let tokenDecimals: String
        let tokenAddress: String
    }
}
