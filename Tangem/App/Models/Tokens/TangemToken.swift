//
//  TangemToken.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
#if !CLIP
import BlockchainSdk
#endif

struct TangemToken: Codable {
    let id: String
    let name: String
    let symbol: String
    let imageURL: URL?
    let contracts: [Contract]
    
    var blockchain: Blockchain? {
        return nil
       // Blockchain.from(blockchainName: self.rawValue, curve: curve)
    }
}

extension TangemToken {
    struct Contract: Codable {
        let blockchain: Blockchain
        let address: String
        let decimalCount: Int
    }
}

extension TangemToken {
    init(with entity: TangemTokenEntity, baseImageURL: URL?) {
        self.id = entity.id.trim()
        self.name = entity.name.trim()
        self.symbol = entity.symbol.uppercased().trim()
        self.imageURL = baseImageURL?
            .appendingPathComponent("large")
            .appendingPathComponent("\(self.id).png")
        self.contracts = entity.contracts?.compactMap { .init(with: $0) } ?? []
    }
}

extension TangemToken.Contract {
    init?(with entity: TangemTokenEntity.ContractEntity) {
        guard let blockchain = entity.networkId.blockchain else {
            return nil
        }
        
        self.blockchain = blockchain
        self.address = entity.address.trim()
        self.decimalCount = entity.decimalCount
    }
}

