//
//  TokenItem.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

enum TokenItem: Codable, Hashable {
    case blockchain(Blockchain)
    case token(Token)
    
    var blockchain: Blockchain? {
        if case let .blockchain(blockchain) = self {
            return blockchain
        }
        return nil
    }
    
    var token: Token? {
        if case let .token(token) = self {
            return token
        }
        return nil
    }
    
    var amountType: Amount.AmountType {
        switch self {
        case .token(let token):
            return .token(value: token)
        case .blockchain:
            return .coin
        }
    }
    
    @ViewBuilder var imageView: some View {
        switch self {
        case .token(let token):
            CircleImageTextView(name: token.name, color: token.color)
        case .blockchain(let blockchain):
            if let image = blockchain.imageName {
                Image(image)
            } else {
                CircleImageTextView(name: blockchain.displayName,
                                color: Color.tangemTapGrayLight4)
            }
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let blockchain = try? container.decode(Blockchain.self) {
            self = .blockchain(blockchain)
        } else if let token = try? container.decode(Token.self) {
            self = .token(token)
        } else {
            throw BlockchainSdkError.decodingFailed
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .blockchain(let blockhain):
            try container.encode(blockhain)
        case .token(let token):
            try container.encode(token)
        }
    }
}
