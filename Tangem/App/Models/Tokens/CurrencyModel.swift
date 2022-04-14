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
    var items: [TokenItem]
    
    init(with entity: CurrencyEntity, baseImageURL: URL?) {
        let id = entity.id.trimmed()
        let name = entity.name.trimmed()
        let symbol = entity.symbol.uppercased().trimmed()
        let url = baseImageURL?.appendingPathComponent("large")
            .appendingPathComponent("\(id).png")
        
        var items: [TokenItem] = []
        
        
        if id == "binancecoin" {
            items.append(.blockchain(.binance(testnet: false)))
            items.append(.blockchain(.bsc(testnet: false)))
        } else if id == "binancecoin/test" {
            items.append(.blockchain(.binance(testnet: true)))
            items.append(.blockchain(.bsc(testnet: true)))
        } else {
            if let blockchain = Blockchain(from: id) {
                items.append(.blockchain(blockchain))
            }
            
            let tokens: [TokenItem]? = entity.contracts?.compactMap {
                if let blockchain = Blockchain(from: $0.networkId),
                   let decimalCount = $0.decimalCount {
                    return .token(Token(name: name,
                                        symbol: symbol,
                                        contractAddress: $0.address.trimmed(),
                                        decimalCount: decimalCount,
                                        id: entity.id),
                                  blockchain)
                }
                
                return nil
            }
            
            tokens.map { items.append(contentsOf: $0) }
        }
        
        self.id = id
        self.name = name
        self.symbol = symbol
        self.imageURL = url
        self.items = items
    }
}
