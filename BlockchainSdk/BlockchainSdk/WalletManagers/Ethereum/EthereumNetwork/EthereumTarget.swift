//
//  EthereumProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum TokenNetwork: String {
    case eth = "https://mainnet.infura.io/v3/613a0b14833145968b1f656240c7d245"
    case rsk = "https://public-node.rsk.co/"
}

enum EthereumTarget: TargetType {
    case balance(address: String)
    case transactions(address: String)
    case pending(address: String)
    case send(transaction: String)
    case tokenBalance(address: String, contractAddress: String, tokenNetwork: TokenNetwork)
    
    var baseURL: URL {
        switch self {
        case .tokenBalance(_, _, let tokenNetwork):
            return URL(string: tokenNetwork.rawValue)!
        default:
            return URL(string: TokenNetwork.eth.rawValue)!
        }
    }
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .balance(let address):
            return  .requestParameters(parameters: ["jsonrpc": "2.0",
                                                    "method": "eth_getBalance",
                                                    "params": [address, "latest"],
                                                    "id": 67],
                                       encoding: URLEncoding.default)
            
        case .transactions(let address):
            return .requestParameters(parameters: ["jsonrpc": "2.0",
                                                   "method": "eth_getTransactionCount",
                                                   "params": [address, "latest"],
                                                   "id": 67],
                                      encoding: URLEncoding.default)
            
        case .pending(let address):
            return .requestParameters(parameters: ["jsonrpc": "2.0",
                                                   "method": "eth_getTransactionCount",
                                                   "params": [address, "pending"],
                                                   "id": 67],
                                      encoding: URLEncoding.default)
            
        case .send(let transaction):
            return .requestParameters(parameters: ["jsonrpc": "2.0",
                                                   "method": "eth_sendRawTransaction",
                                                   "params": [transaction], "id": 67],
                                      encoding: URLEncoding.default)
            
        case .tokenBalance(let address, let contractAddress, _):
            let rawAddress = address[address.index((address.startIndex), offsetBy: 2)...]
            let dataValue = ["data": "0x70a08231000000000000000000000000\(rawAddress)", "to": contractAddress]
            return .requestParameters(parameters: ["method": "eth_call",
                                                   "params": [dataValue, "latest"],
                                                   "id": 03],
                                      encoding: URLEncoding.default)
            
        }
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
}
