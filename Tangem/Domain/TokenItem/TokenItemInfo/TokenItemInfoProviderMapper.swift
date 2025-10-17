//
//  TokenItemInfoProviderMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUI.TokenIconInfo

typealias TokenItemInfoProviderItem = (id: WalletModelId, provider: TokenItemInfoProvider, tokenItem: TokenItem, tokenIconInfo: TokenIconInfo)

struct TokenItemInfoProviderItemBuilder {
    func mapTokenItemViewModel(from tokenItemType: TokenItemType) -> TokenItemInfoProviderItem {
        switch tokenItemType {
        case .default(let walletModel):
            let tokenItem = walletModel.tokenItem
            let tokenIconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: walletModel.isCustom)

            return TokenItemInfoProviderItem(
                id: walletModel.id,
                provider: DefaultTokenItemInfoProvider(walletModel: walletModel),
                tokenItem: tokenItem,
                tokenIconInfo: tokenIconInfo
            )
        case .withoutDerivation(let tokenItem):
            let tokenIconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: false)

            return TokenItemInfoProviderItem(
                id: WalletModelId(tokenItem: tokenItem),
                provider: TokenWithoutDerivationInfoProvider(),
                tokenItem: tokenItem,
                tokenIconInfo: tokenIconInfo
            )
        }
    }
}
