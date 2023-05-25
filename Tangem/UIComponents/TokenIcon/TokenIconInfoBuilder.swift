//
//  TokenIconInfoBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TokenIconInfoBuilder {
    func build(for type: Amount.AmountType, in blockchain: Blockchain) -> TokenIconInfo {
        let id: String?
        let name: String
        var blockchainIconName: String?
        var imageURL: URL?

        switch type {
        case .coin, .reserve:
            id = blockchain.id
            name = blockchain.displayName
        case .token(let token):
            id = token.id
            name = token.name
            blockchainIconName = blockchain.iconNameFilled
        }

        if let id {
            imageURL = TokenIconURLBuilder(baseURL: CoinsResponse.baseURL)
                .iconURL(id: id, size: .large)
        }

        return .init(name: name, blockchainIconName: blockchainIconName, imageURL: imageURL)
    }
}
