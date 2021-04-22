//
//  BlockcypherTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct BlockcypherEndpoint {
    let coin: BlockcypherCoin
    let chain: BlockcypherChain
    
    var blockchain: Blockchain {
        switch (coin,chain) {
        case (.btc, .main):
            return .bitcoin(testnet: false)
        case (.btc, .test3):
            return .bitcoin(testnet: true)
        case (.eth, .main):
            return .ethereum(testnet: false)
        case (.eth, .test3):
            return .ethereum(testnet: true)
        case (.ltc, .main), (.ltc, .test3):
            return .litecoin
        }
    }
}

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
		case address(address: String, unspentsOnly: Bool, limit: Int?)
        case fee
        case send(txHex: String)
        case txs(txHash: String)
    }
    
    let endpoint: BlockcypherEndpoint
    let token: String?
    let targetType: BlockcypherTargetType
    
    var baseURL: URL { URL(string: "https://api.blockcypher.com/v1/\(endpoint.coin.rawValue)/\(endpoint.chain.rawValue)")! }
    
    var path: String {
        switch targetType {
        case .address(let address, _, _):
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
        case .address(_, let unspentsOnly, let limit):
			if unspentsOnly {
				parameters["unspentOnly"] = "true"
			}
            parameters["includeScript"] = "true"
			if let limit = limit {
				parameters["limit"] = "\(limit)"
			}
        case .send(let txHex):
            return .requestCompositeParameters(bodyParameters: ["tx": txHex],
                                               bodyEncoding: JSONEncoding.default,
                                               urlParameters: parameters)
        default:
            break
        }
        
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String : String]? {
        return nil
    }
}
