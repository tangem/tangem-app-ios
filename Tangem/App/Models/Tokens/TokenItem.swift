//
//  TokenItem.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Kingfisher
import SwiftUI
import struct TangemSdk.DerivationPath

struct TokenItem: Hashable {
    var id: String?
    var isCustom: Bool
    let item: RawItem
    
    var isBlockchain: Bool { token == nil }
    
    var blockchain: Blockchain {
        switch item {
        case .token(let token):
            return token.blockchain
        case .blockchain(let blockchain):
            return blockchain
        }
    }
    
    var derivationPath: DerivationPath? {
        _derivationPath ?? blockchain.derivationPath
    }
    
    var token: Token? {
        if case let .token(token) = item {
            return token
        }
        return nil
    }
    
    var name: String {
        switch item {
        case .token(let token):
            return token.name
        case .blockchain(let blockchain):
            return blockchain.displayName
        }
    }
    
    var contractName: String? {
        switch item {
        case .token:
            switch blockchain {
            case .binance: return "BEP2"
            case .bsc: return "BEP20"
            case .ethereum: return "ERC20"
            default:
                return nil
            }
        case .blockchain:
            return "MAIN"
        }
    }
    
    var symbol: String {
        switch item {
        case .token(let token):
            return token.symbol
        case .blockchain(let blockchain):
            return blockchain.currencySymbol
        }
    }
    
    var contractAddress: String? {
        token?.contractAddress
    }
    
    var amountType: Amount.AmountType {
        switch item {
        case .token(let token):
            return .token(value: token)
        case .blockchain:
            return .coin
        }
    }
    
    var iconView: TokenIconView {
        TokenIconView(token: self)
    }
    
    @ViewBuilder fileprivate var imageView: some View {
        switch item {
        case .token(let token):
            CircleImageTextView(name: token.name, color: token.color)
        case .blockchain(let blockchain):
            Image(blockchain.iconNameFilled)
                .resizable()
        }
    }
    
    fileprivate var imageURL: URL? {
        switch item {
        case .blockchain(let blockchain):
            return IconsUtils.getBlockchainIconUrl(blockchain).flatMap { URL(string: $0.absoluteString) }
        case .token(let token):
            return token.customIconUrl.flatMap{ URL(string: $0) }
        }
    }
    
    private let _derivationPath: DerivationPath?
    
    init(_ blockchain: Blockchain, id: String? = nil, derivationPath: DerivationPath? = nil, isCustom: Bool = false) {
        self.init(item: .blockchain(blockchain), id: id, derivationPath: derivationPath, isCustom: isCustom)
    }
    
    init(_ token: Token, id: String? = nil, derivationPath: DerivationPath? = nil, isCustom: Bool = false) {
        self.init(item: .token(token), id: id, derivationPath: derivationPath, isCustom: isCustom)
    }
    
    private init(item: TokenItem.RawItem, id: String?, derivationPath: DerivationPath?, isCustom: Bool) {
        self.id = id
        self.item = item
        self._derivationPath = derivationPath
        self.isCustom = isCustom
    }
}

extension TokenItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case item
        case _derivationPath = "derivationPath"
        case isCustom
    }
    
    init(from decoder: Decoder) throws {
        if let itemContainer = try? decoder.container(keyedBy: CodingKeys.self),
           let item = try? itemContainer.decode(TokenItem.RawItem.self, forKey: CodingKeys.item),
           let isCustom = try? itemContainer.decode(Bool.self, forKey: CodingKeys.isCustom)
        {
            let id = try? itemContainer.decode(String.self, forKey: CodingKeys.id)
            let derivationPath = try? itemContainer.decode(DerivationPath.self, forKey: CodingKeys._derivationPath)
            self = .init(item: item, id: id, derivationPath: derivationPath, isCustom: isCustom)
            return
        } else {
            let container = try decoder.singleValueContainer()
            
            if let token = try? container.decode(Token.self) {
                self = .init(token)
                return
            }
            
            if let blockchain = try? container.decode(Blockchain.self) {
                self = .init(blockchain)
                return
            }
            
            if let tokenDto = try? container.decode(TokenDTO.self) {
                let token = Token(name: tokenDto.name,
                                  symbol: tokenDto.symbol,
                                  contractAddress: tokenDto.contractAddress,
                                  decimalCount: tokenDto.decimalCount,
                                  customIconUrl: tokenDto.customIconUrl,
                                  blockchain: .ethereum(testnet: false))
                self = .init(token)
                return
            }
        }
        
        throw BlockchainSdkError.decodingFailed
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

struct TokenIconView: View {
    var token: TokenItem
    var size: CGSize = .init(width: 80, height: 80)
    
    var body: some View {
        if let url = token.imageURL {
        #if !CLIP
            KFImage(url)
                .placeholder { token.imageView }
                .setProcessor(DownsamplingImageProcessor(size: size))
                .cacheOriginalImage()
                .scaleFactor(UIScreen.main.scale)
                .resizable()
                .scaledToFit()
                .cornerRadius(5)
        #else
            WebImage(imagePath: url, placeholder: token.imageView.toAnyView())
        #endif
        } else {
            token.imageView
        }
    }
}

extension TokenIconView {
    init(with type: Amount.AmountType, blockchain: Blockchain) {
        if case let .token(token) = type {
            self.token = .init(token)
        }
        
        self.token = .init(blockchain)
    }
}

extension TokenItem {
    enum RawItem: Codable, Hashable {
        case blockchain(Blockchain)
        case token(Token)
    }
}
