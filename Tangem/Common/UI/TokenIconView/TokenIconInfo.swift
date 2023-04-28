//
//  TokenIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TokenIconInfo: Hashable {
    let name: String

    var blockchainIconName: String?
    var imageURL: URL?

    init(with type: Amount.AmountType, blockchain: Blockchain) {
        let id: String?
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
    }
}
