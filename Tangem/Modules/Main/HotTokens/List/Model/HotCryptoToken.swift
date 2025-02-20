//
//  HotCryptoDataItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HotCryptoToken: Identifiable {
    let id: String
    let coinId: String
    let name: String
    let networkId: String
    let currentPrice: Decimal?
    let priceChangePercentage24h: Decimal?
    let symbol: String
    let decimalCount: Int?
    let contractAddress: String?
    let tokenIconInfo: TokenIconInfo?
}

extension HotCryptoToken {
    // [REDACTED_TODO_COMMENT]
    init(from dto: HotCryptoDTO.Response.HotToken, tokenMapper: TokenItemMapper, imageHost: URL?) {
        id = dto.id + dto.networkId
        coinId = dto.id
        name = dto.name
        symbol = dto.symbol
        networkId = dto.networkId
        currentPrice = dto.currentPrice
        priceChangePercentage24h = dto.priceChangePercentage24h
        decimalCount = dto.decimalCount
        contractAddress = dto.contractAddress

        guard
            let mappedTokenItem = tokenMapper.mapToTokenItem(
                id: coinId,
                name: name,
                symbol: symbol,
                network: .init(networkId: networkId, contractAddress: contractAddress, decimalCount: decimalCount)
            )
        else {
            tokenIconInfo = nil
            return
        }

        tokenIconInfo = TokenIconInfoBuilder().build(from: mappedTokenItem, isCustom: false)
    }
}
