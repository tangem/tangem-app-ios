//
//  CurrencyModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CurrencyModel {
    let id: String
    let name: String
    let symbol: String
    let imageURL: URL?
    let items: [TokenItem]
    
    init(with entity: CurrencyEntity, baseImageURL: URL?) {
        let id = entity.id.trimmed()
        let name = entity.name.trimmed()
        let symbol = entity.symbol.uppercased().trimmed()
        let url = baseImageURL?.appendingPathComponent("large")
            .appendingPathComponent("\(id).png")
        
        var items: [TokenItem] = []
        
        if let blockchain = Blockchain(from: id) {
            items.append(.init(blockchain))
            
            if id == "binancecoin", let bsc = Blockchain(from: "binance-smart-chain") {
                items.append(.init(bsc))
            } else if id == "binancecoin/test", let bsc = Blockchain(from: "binance-smart-chain/test") {
                items.append(.init(bsc))
            }
            
        }
        
        let tokens: [TokenItem]? = entity.contracts?.compactMap {
            guard let blockchain = Blockchain(from: $0.networkId) else {
                return nil
            }
            
            return .init(Token(name: name,
                               symbol: symbol,
                               contractAddress: $0.address.trimmed(),
                               decimalCount: $0.decimalCount,
                               customIconUrl: url?.absoluteString,
                               blockchain: blockchain),
                         id: id)
        }
        
        tokens.map { items.append(contentsOf: $0) }
        
        self.id = id
        self.name = name
        self.symbol = symbol
        self.imageURL = url
        self.items = items
    }
}
