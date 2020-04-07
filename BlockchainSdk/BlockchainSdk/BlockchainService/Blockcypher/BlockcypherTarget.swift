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
}

enum BlockcypherChain: String {
    case main
    case test3
}

enum BlockcypherTarget: TargetType {
    case address(address:String, coin: BlockcypherCoin, chain: BlockcypherChain)
    case fee(coin: BlockcypherCoin, chain: BlockcypherChain)
    case send(txHex: String, coin: BlockcypherCoin, chain: BlockcypherChain, accessToken: String)
    
    var baseURL: URL {
        switch self {
        case .address(_, let coin, let chain):
            return baseUrl(coin: coin, chain: chain)
        case .fee(let coin, let chain):
            return baseUrl(coin: coin, chain: chain)
        case .send(_, let coin, let chain, _):
            return baseUrl(coin: coin, chain: chain)
        }
    }
    
    var path: String {
        switch self {
        case .address(let address, _, _):
            return "/addrs/\(address)?unspentOnly=true&includeScript=true"
        case .fee:
            return ""
        case .send(_, _, _, let token):
            return "/txs/push?token=\(token)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address:
            return .get
        case .fee:
            return .post
        case .send:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .send(let txHex):
            return .requestParameters(parameters: ["tx": txHex], encoding: URLEncoding.default)
        default:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    private func baseUrl(coin: BlockcypherCoin, chain: BlockcypherChain) -> URL {
        return URL(string: "https://api.blockcypher.com/v1/\(coin.rawValue)/\(chain.rawValue)")!
    }
}
