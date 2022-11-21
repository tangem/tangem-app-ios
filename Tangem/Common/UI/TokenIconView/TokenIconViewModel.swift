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
    let id: String?
    let name: String
    let style: Style

    var imageURL: URL? {
        guard let id else { return nil }

        return CoinsResponse.baseURL
            .appendingPathComponent("coins")
            .appendingPathComponent("large")
            .appendingPathComponent("\(id).png")
    }

    var blockchainIconName: String? {
        if case let .token(iconName) = style {
            return iconName
        }

        return nil
    }

    init(
        id: String?,
        name: String,
        style: TokenIconViewModel.Style
    ) {
        self.id = id
        self.name = name
        self.style = style
    }

    init(tokenItem: TokenItem) {
        switch tokenItem {
        case let .blockchain(blockchain):
            self.init(id: blockchain.id, name: blockchain.displayName, style: .blockchain)
        case let .token(token, blockchain):
            self.init(id: token.id, name: token.name, style: .token(blockchainIconName: blockchain.iconNameFilled))
        }
    }

    init(with type: Amount.AmountType, blockchain: Blockchain) {
        switch type {
        case .coin, .reserve:
            self.init(id: blockchain.id, name: blockchain.displayName, style: .blockchain)
        case .token(let token):
            self.init(id: token.id, name: token.name, style: .token(blockchainIconName: blockchain.iconNameFilled))
        }
    }
}

extension TokenIconViewModel {
    enum Style: Hashable {
        case token(blockchainIconName: String)
        case blockchain
    }
}
