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
        case (.doge, _):
            return .dogecoin
        }
    }
}

enum BlockcypherCoin: String {
    case btc
    case ltc
    case eth
    case doge
}

enum BlockcypherChain: String {
    case main
    case test3
}

struct BlockcypherTarget: TargetType {
    enum BlockcypherTargetType {
		case address(address: String, unspentsOnly: Bool, limit: Int?)
    }
    
    let endpoint: BlockcypherEndpoint
    let token: String?
    let targetType: BlockcypherTargetType
    
    var baseURL: URL { URL(string: "https://api.blockcypher.com/v1/\(endpoint.coin.rawValue)/\(endpoint.chain.rawValue)")! }
    
    var path: String {
        switch targetType {
        case .address(let address, _, _):
            return "/addrs/\(address)"
        }
    }
    
    var method: Moya.Method {
        switch targetType {
        case .address:
            return .get
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
        }
        
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String : String]? {
        return nil
    }
}
