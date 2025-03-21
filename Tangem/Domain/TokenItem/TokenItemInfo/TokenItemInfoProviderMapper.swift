//
//  TokenItemInfoProviderMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

typealias TokenItemInfoProviderItem = (id: WalletModelId, provider: TokenItemInfoProvider, tokenItem: TokenItem, tokenIconInfo: TokenIconInfo)

struct TokenItemInfoProviderItemBuilder {
    func mapTokenItemViewModel(from tokenItemType: TokenItemType) -> TokenItemInfoProviderItem {
        switch tokenItemType {
        case .default(let walletModel):
            let tokenItem = walletModel.tokenItem
            let tokenIconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: walletModel.isCustom)

            return (
                id: walletModel.id,
                provider: DefaultTokenItemInfoProvider(walletModel: walletModel),
                tokenItem: tokenItem,
                tokenIconInfo: tokenIconInfo
            )
        case .withoutDerivation(let userToken):
            let tokenItem: TokenItem = {
                let converter = StorageEntryConverter()
                let blockchainNetwork = userToken.blockchainNetwork

                if let token = converter.convertToToken(userToken) {
                    return .token(token, blockchainNetwork)
                }

                return .blockchain(blockchainNetwork)
            }()

            let tokenIconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: userToken.isCustom)

            return (
                id: userToken.walletModelId,
                provider: TokenWithoutDerivationInfoProvider(),
                tokenItem: tokenItem,
                tokenIconInfo: tokenIconInfo
            )
        }
    }
}
