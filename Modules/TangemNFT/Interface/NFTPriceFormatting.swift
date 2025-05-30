//
//  NFTPriceFormatting.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol NFTPriceFormatting {
    func formatCryptoPrice(_ cryptoPrice: Decimal, in nftChain: NFTChain) -> String
    func convertToFiatAndFormatCryptoPrice(_ cryptoPrice: Decimal, in nftChain: NFTChain) async -> String
}
