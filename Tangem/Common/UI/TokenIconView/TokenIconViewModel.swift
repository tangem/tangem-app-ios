//
//  TokenIconViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TokenIconViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let imageURL: URL?
    let name: String
    let style: Style

    init(
        imageURL: URL?,
        name: String,
        style: TokenIconViewModel.Style
    ) {
        self.imageURL = imageURL
        self.name = name
        self.style = style
    }

    init(
        id: String?,
        name: String,
        style: TokenIconViewModel.Style
    ) {
        var imageURL: URL?

        if let id {
            imageURL = TokenIconURLBuilder().iconURL(id: id)
        }

        self.init(
            imageURL: imageURL,
            name: name,
            style: style
        )
    }

    init(tokenItem: TokenItem) {
        switch tokenItem {
        case let .blockchain(blockchain):
            self.init(id: blockchain.id, name: blockchain.displayName, style: .blockchain)
        case let .token(token, blockchain):
            self.init(id: token.id, name: token.name, style: .tokenCoinIconName(blockchain.iconNameFilled))
        }
    }

    init(with type: Amount.AmountType, blockchain: Blockchain) {
        switch type {
        case .coin, .reserve:
            self.init(id: blockchain.id, name: blockchain.displayName, style: .blockchain)
        case .token(let token):
            self.init(id: token.id, name: token.name, style: .tokenCoinIconName(blockchain.iconNameFilled))
        }
    }
}

extension TokenIconViewModel {
    enum Style: Hashable {
        case blockchain
        case tokenCoinIconName(_ iconName: String)
        case tokenCoinIconURL(_ iconURL: URL)
    }
}
