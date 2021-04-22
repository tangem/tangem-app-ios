//
//  EthereumProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum InfuraTarget: TargetType {
    static let infuraTokenId = 03
    static let infuraCoinId = 67
    
    case balance(address: String, network: EthereumNetwork)
    case transactions(address: String, network: EthereumNetwork)
    case pending(address: String, network: EthereumNetwork)
    case send(transaction: String, network: EthereumNetwork)
    case tokenBalance(address: String, contractAddress: String, network: EthereumNetwork)
    case gasPrice(to: String, from: String, data: String?, network: EthereumNetwork)
    
    var baseURL: URL {
        switch self {
        case .balance(_, let network): return network.url
        case .pending(_, let network): return network.url
        case .send(_, let network): return network.url
        case .tokenBalance(_, _, let network): return network.url
        case .transactions(_, let network): return network.url
        case .gasPrice(_, _, _, let network): return network.url
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
        case .balance(let address, _):
            return  .requestParameters(parameters: ["jsonrpc": "2.0",
                                                    "method": "eth_getBalance",
                                                    "params": [address, "latest"],
                                                    "id": InfuraTarget.infuraCoinId],
                                       encoding: JSONEncoding.default)
            
        case .transactions(let address, _):
            return .requestParameters(parameters: ["jsonrpc": "2.0",
                                                   "method": "eth_getTransactionCount",
                                                   "params": [address, "latest"],
                                                   "id": InfuraTarget.infuraCoinId],
                                      encoding: JSONEncoding.default)
            
        case .pending(let address, _):
            return .requestParameters(parameters: ["jsonrpc": "2.0",
                                                   "method": "eth_getTransactionCount",
                                                   "params": [address, "pending"],
                                                   "id": InfuraTarget.infuraCoinId],
                                      encoding: JSONEncoding.default)
            
        case .send(let transaction, _):
            return .requestParameters(parameters: ["jsonrpc": "2.0",
                                                   "method": "eth_sendRawTransaction",
                                                   "params": [transaction],
                                                   "id": InfuraTarget.infuraCoinId],
                                      encoding: JSONEncoding.default)
            
        case .tokenBalance(let address, let contractAddress, _):
            let rawAddress = address[address.index((address.startIndex), offsetBy: 2)...]
            let dataValue = ["data": "0x70a08231000000000000000000000000\(rawAddress)", "to": contractAddress]
            return .requestParameters(parameters: ["jsonrpc": "2.0",
                                                   "method": "eth_call",
                                                   "params": [dataValue, "latest"],
                                                   "id": InfuraTarget.infuraTokenId],
                                      encoding: JSONEncoding.default)
        case .gasPrice(let to, let from, let data, network: _):
            var params = [String:String]()
            params["from"] = from
            params["to"] = to
            if let data = data {
                params["data"] = data
            }
            return .requestParameters(parameters: ["jsonrpc": "2.0",
                                                   "method": "eth_estimateGas",
                                                   "params": [params],
                                                   "id": InfuraTarget.infuraCoinId],
                                      encoding: JSONEncoding.default)
            
        }
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
}
