//
//  NFTPriceFormatterMock.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NFTPriceFormatterMock: NFTPriceFormatting {
    func formatCryptoPrice(_ cryptoPrice: Decimal, in nftChain: NFTChain) -> String {
        let currencyCode: String
        switch nftChain {
        case .solana:
            currencyCode = "SOL"
        default:
            currencyCode = "ETH"
        }

        return "\(cryptoPrice.formatted(.number.precision(.fractionLength(..<3)))) \(currencyCode)"
    }

    func convertToFiatAndFormatCryptoPrice(_ cryptoPrice: Decimal, in nftChain: NFTChain) async -> String {
        return "\(cryptoPrice.formatted(.number.precision(.fractionLength(..<3)))) $"
    }
}
