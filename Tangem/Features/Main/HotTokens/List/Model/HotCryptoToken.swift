//
//  HotCryptoDataItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HotCryptoToken: Identifiable {
    let id = UUID()
    let name: String
    let currentPrice: Decimal?
    let priceChangePercentage24h: Decimal?
    let tokenItem: TokenItem?
    let tokenIconInfo: TokenIconInfo?
}

extension HotCryptoToken {
    // [REDACTED_TODO_COMMENT]
    init(from dto: HotCryptoDTO.Response.HotToken, tokenMapper: TokenItemMapper, imageHost: URL?) {
        currentPrice = dto.currentPrice
        priceChangePercentage24h = dto.priceChangePercentage24h

        guard
            let mappedTokenItem = tokenMapper.mapToTokenItem(
                id: dto.id,
                name: dto.name,
                symbol: dto.symbol,
                network: .init(
                    networkId: dto.networkId,
                    contractAddress: dto.contractAddress,
                    decimalCount: dto.decimalCount
                )
            )
        else {
            name = dto.name
            tokenItem = nil
            tokenIconInfo = nil
            return
        }

        name = mappedTokenItem.name
        tokenItem = mappedTokenItem
        tokenIconInfo = TokenIconInfoBuilder().build(from: mappedTokenItem, isCustom: false)
    }
}
