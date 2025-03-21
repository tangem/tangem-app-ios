//
//  TokenIconInfoBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import BlockchainSdk
import TangemAssets

struct TokenIconInfoBuilder {
    func build(for type: Amount.AmountType, in blockchain: Blockchain, isCustom: Bool) -> TokenIconInfo {
        let id: String?
        let name: String
        var blockchainIconAsset: ImageType?
        var imageURL: URL?
        var customTokenColor: Color?

        switch type {
        case .coin, .reserve, .feeResource:
            id = blockchain.coinId
            name = blockchain.coinDisplayName
        case .token(let token):
            id = token.id
            name = token.name
            blockchainIconAsset = blockchain.iconAssetFilled
            customTokenColor = token.customTokenColor
        }

        if let id {
            imageURL = IconURLBuilder()
                .tokenIconURL(id: id, size: .large)
        }

        return .init(name: name, blockchainIconAsset: blockchainIconAsset, imageURL: imageURL, isCustom: isCustom, customTokenColor: customTokenColor)
    }

    func build(from tokenItem: TokenItem, isCustom: Bool) -> TokenIconInfo {
        build(for: tokenItem.amountType, in: tokenItem.blockchain, isCustom: isCustom)
    }

    func build(from currencyCode: String) -> TokenIconInfo {
        TokenIconInfo(
            name: "",
            blockchainIconAsset: nil,
            imageURL: IconURLBuilder().fiatIconURL(currencyCode: currencyCode),
            isCustom: false,
            customTokenColor: nil
        )
    }
}
