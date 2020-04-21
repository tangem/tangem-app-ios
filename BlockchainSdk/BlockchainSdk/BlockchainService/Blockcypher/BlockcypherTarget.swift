//
//  BlockcypherTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum BlockcypherCoin: String {
    case btc
    case ltc
    case eth
}

enum BlockcypherChain: String {
    case main
    case test3
}

struct BlockcypherTarget: TargetType {
    enum BlockcypherTargetType {
        case address(address:String)
        case fee
        case send(txHex: String)
        case txs(txHash: String)
    }
    
    let coin: BlockcypherCoin
    let chain: BlockcypherChain
    let token: String?
    let targetType: BlockcypherTargetType
    
    var baseURL: URL { URL(string: "https://api.blockcypher.com/v1/\(coin.rawValue)/\(chain.rawValue)")! }
    
    var path: String {
        switch targetType {
        case .address(let address):
            return "/addrs/\(address)"
        case .fee:
            return ""
        case .send:
            return "/txs/push"
        case .txs(let txHash):
            return "/txs/\(txHash)"
        }
    }
    
    var method: Moya.Method {
        switch targetType {
        case .address, .fee, .txs:
            return .get
        case .send:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        var parameters = token == nil ? [:] : ["token":token!]
        
        switch targetType {
        case .address:
            parameters["unspentOnly"] = "true"
            parameters["includeScript"] = "true"
        case .send(let txHex):
            parameters["tx"] = txHex
        default: break
        }
        
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String : String]? {
        return nil
    }
}
