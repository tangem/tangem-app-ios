//
//  EthereumNetwork.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public enum EthereumNetwork {
    case mainnet(projectId: String)
    case testnet(projectId: String)
    case tangem
    case rsk
    case bscMainnet
    case bscTestnet
    case polygon
    case polygonTestnet
    case avalanche //c-chain
    case avalancheTestnet //c-chain
    
    public var blockchain: Blockchain {
        switch self {
        case .mainnet, .tangem: return .ethereum(testnet: false)
        case .testnet: return .ethereum(testnet: true)
        case .rsk: return .rsk
        case .bscMainnet: return .bsc(testnet: false)
        case .bscTestnet: return .bsc(testnet: true)
        case .polygon: return .polygon(testnet: false)
        case .polygonTestnet: return .polygon(testnet: true)
        case .avalanche: return .avalanche(testnet: false)
        case .avalancheTestnet: return .avalanche(testnet: true)
        }
    }
    
    public var id: Int {
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
        case .polygon:
            return 137
        case .polygonTestnet:
            return 80001
        case .avalanche:
            return 43114
        case .avalancheTestnet:
            return 43113
        }
    }
    
    var chainId: BigUInt { return BigUInt(self.id) }
    
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
        case .polygon:
            return URL(string: "https://rpc-mainnet.maticvigil.com/")!
        case .polygonTestnet:
            return URL(string: "https://rpc-mumbai.maticvigil.com/")!
        case .avalanche:
            return URL(string: "https://api.avax.network/ext/bc/C/rpc")!
        case .avalancheTestnet:
            return URL(string: "https://api.avax-test.network/ext/bc/C/rpc")!
        }
    }
    
    public static func network(for id: Int) -> EthereumNetwork? {
        switch id {
        case EthereumNetwork.bscMainnet.id:
            return .bscMainnet
        case EthereumNetwork.bscTestnet.id:
            return .bscTestnet
        case EthereumNetwork.mainnet(projectId: "").id:
            return .mainnet(projectId: "")
        case EthereumNetwork.testnet(projectId: "").id:
            return .testnet(projectId: "")
        case EthereumNetwork.polygon.id:
            return .polygon
        case EthereumNetwork.polygonTestnet.id:
            return .polygonTestnet
        case EthereumNetwork.avalanche.id:
            return .avalanche
        case EthereumNetwork.avalancheTestnet.id:
            return .avalancheTestnet
        default:
            return nil
        }
    }
}
