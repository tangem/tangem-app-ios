//
//  TokenItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
#if !CLIP
import BlockchainSdk
#endif
import SwiftUI

enum TokenItem: Codable, Hashable, Identifiable {
    case blockchain(Blockchain)
    case token(Token)
    
    var id: Int {
        switch self {
        case .token(let token):
            return token.hashValue
        case .blockchain(let blockchain):
            return blockchain.hashValue
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .token(let token):
            return token.blockchain
        case .blockchain(let blockchain):
            return blockchain
        }
    }
    
    var token: Token? {
        if case let .token(token) = self {
            return token
        }
        return nil
    }
    
    var name: String {
        switch self {
        case .token(let token):
            return token.name
        case .blockchain(let blockchain):
            return blockchain.displayName
        }
    }
    
    var symbol: String {
        switch self {
        case .token(let token):
            return token.symbol
        case .blockchain(let blockchain):
            return blockchain.currencySymbol
        }
    }
    
    var contractAddress: String? {
        switch self {
        case .token(let token):
            return token.contractAddress
        case .blockchain:
            return nil
        }
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
            if let iconName = token.customIcon {
                Image(iconName)
                    .resizable()
            } else {
                CircleImageTextView(name: token.name, color: token.color)
            }
        case .blockchain(let blockchain):
            if let image = blockchain.imageName {
                Image(image)
                    .resizable()
            } else {
                CircleImageTextView(name: blockchain.displayName,
                                color: Color.tangemGrayLight4)
            }
        }
    }
    
    var imagePath: String? {
        switch self {
        case .blockchain(let blockchain):
            return IconsUtils.getBlockchainIconUrl(blockchain)?.absoluteString
        case .token(let token):
            guard token.customIcon == nil else { return nil }
            
            if let url = token.customIconUrl {
                return url
            }
            
            return IconsUtils.getTokenIconUrl(token: token)?.absoluteString
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let blockchain = try? container.decode(Blockchain.self) {
            self = .blockchain(blockchain)
        } else if let token = try? container.decode(Token.self) {
            self = .token(token)
        } else if let tokenDto = try? container.decode(TokenDTO.self) {
            self = .token(Token(name: tokenDto.name,
                                symbol: tokenDto.symbol,
                                contractAddress: tokenDto.contractAddress,
                                decimalCount: tokenDto.decimalCount,
                                customIcon: tokenDto.customIcon,
                                customIconUrl: tokenDto.customIconUrl,
                                blockchain: .ethereum(testnet: false)))
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

struct TokenDTO: Decodable {
    let name: String
    let symbol: String
    let contractAddress: String
    let decimalCount: Int
    let customIcon: String?
    let customIconUrl: String?
}
