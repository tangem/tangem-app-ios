//
//  BlockchairTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum BlockchairEndpoint: String {
	case bitcoin = "bitcoin"
    case bitcoinCash = "bitcoin-cash"
	case litecoin = "litecoin"
    case dogecoin
    case ethereum
    
    var blockchain: Blockchain {
        switch self {
        case .bitcoin:
            return .bitcoin(testnet: false)
        case .bitcoinCash:
            return .bitcoinCash(testnet: false)
		case .litecoin:
			return .litecoin
        case .dogecoin:
            return .dogecoin
        case .ethereum:
            return .ethereum(testnet: false)
        }
    }
}

enum BlockchairTarget: TargetType {
    case address(address: String, endpoint: BlockchairEndpoint = .bitcoinCash, transactionDetails: Bool, apiKey: String)
    case findErc20Tokens(address: String, apiKey: String)
    
    var baseURL: URL {
        var endpointString = ""
        
        switch self {
        case .address(_, let endpoint, _, _):
            endpointString = endpoint.rawValue
        case .findErc20Tokens:
            endpointString = BlockchairEndpoint.ethereum.rawValue
        }
        
        return URL(string: "https://api.blockchair.com/\(endpointString)")!
    }
    
    var path: String {
        switch self {
        case .address(let address, _, _, _):
            return "/dashboards/address/\(address)"
        case .findErc20Tokens(address: let address, _):
            return "/dashboards/address/\(address)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address, .findErc20Tokens:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        var parameters = [String:String]()
        var key: String
        switch self {
        case .address(_, _, let details, let apiKey):
            key = apiKey
            parameters["transaction_details"] = "\(details)"
        case .findErc20Tokens(address: let address, apiKey: let apiKey):
            key = apiKey
            parameters["erc_20"] = "true"
        }
        parameters["key"] = key
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String: String]? {
        switch self {
        case .address, .findErc20Tokens:
            return ["Content-Type": "application/json"]
        }
    }
}
