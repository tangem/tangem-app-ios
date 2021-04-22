//
//  EthereumNetwork.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

enum EthereumNetwork {
    case mainnet(projectId: String)
    case testnet(projectId: String)
    case rsk
    
    var chainId: BigUInt { return BigUInt(self.id) }
    
    var id: Int {
        switch self {
        case .mainnet:
           return 1
        case .testnet:
            return 4
        case .rsk:
            return 30
        }
    }
    
    var url: URL {
        switch self {
        case .mainnet(let projectId):
            return URL(string: "https://mainnet.infura.io/v3/\(projectId)")!
        case .testnet(let projectId):
            return URL(string:"https://rinkeby.infura.io/v3/\(projectId)")!
        case .rsk:
            return URL(string: "https://public-node.rsk.co/")!
        }
    }
}
