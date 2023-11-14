//
//  TokenIconItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TokenIconItemViewModel {
    let imageURL: URL?
    let networkURL: URL?

    init(imageURL: URL, networkURL: URL? = nil) {
        self.imageURL = imageURL
        self.networkURL = networkURL
    }

    init?(tokenItem: TokenItem) {
        let builder = TokenIconURLBuilder()

        if let id = tokenItem.id {
            imageURL = builder.iconURL(id: id, size: .large)
        } else {
            imageURL = nil
        }

        if tokenItem.isToken {
            networkURL = builder.iconURL(id: tokenItem.blockchain.coinId, size: .small)
        } else {
            networkURL = nil
        }
    }
}
