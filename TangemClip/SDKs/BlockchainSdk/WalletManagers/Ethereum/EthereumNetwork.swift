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
    case tangem
    case rsk
    case bscMainnet
    case bscTestnet
    case maticMainnet
    case maticTestnet
    
    var chainId: BigUInt { return BigUInt(self.id) }
    
    var blockchain: Blockchain {
        switch self {
        case .mainnet, .tangem: return .ethereum(testnet: false)
        case .testnet: return .ethereum(testnet: true)
        case .rsk: return .rsk
        case .bscMainnet: return .bsc(testnet: false)
        case .bscTestnet: return .bsc(testnet: true)
        case .maticMainnet: return .matic(testnet: false)
        case .maticTestnet: return .matic(testnet: true)
        }
    }
    
    var id: Int {
        switch self {
        case .mainnet, .tangem:
           return 1
        case .testnet:
            return 4
        case .rsk:
            return 30
        case .bscMainnet:
            return 56
        case .bscTestnet:
            return 97
        case .maticMainnet:
            return 137
        case .maticTestnet:
            return 80001
        }
    }
    
    var url: URL {
        switch self {
        case .mainnet(let projectId):
            return URL(string: "https://mainnet.infura.io/v3/\(projectId)")!
        case .testnet(let projectId):
            return URL(string:"https://rinkeby.infura.io/v3/\(projectId)")!
        case .tangem:
            return URL(string: "https://eth.tangem.com/")!
        case .rsk:
            return URL(string: "https://public-node.rsk.co/")!
        case .bscMainnet:
            return URL(string: "https://bsc-dataseed.binance.org/")!
        case .bscTestnet:
            return URL(string: "https://data-seed-prebsc-1-s1.binance.org:8545/")!
        case .maticMainnet:
            return URL(string: "https://rpc-mainnet.maticvigil.com/")!
        case .maticTestnet:
            return URL(string: "https://rpc-mumbai.maticvigil.com/")!
        }
    }
}
