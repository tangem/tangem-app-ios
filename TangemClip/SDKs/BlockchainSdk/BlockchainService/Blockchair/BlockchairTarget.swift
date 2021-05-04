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
    case ethereum
    
    var blockchain: Blockchain {
        switch self {
        case .bitcoin:
            return .bitcoin(testnet: false)
        case .bitcoinCash:
            return .bitcoinCash(testnet: false)
		case .litecoin:
			return .litecoin
        case .ethereum:
            return .ethereum(testnet: false)
        }
    }
}

enum BlockchairTarget: TargetType {
    case address(address: String, endpoint: BlockchairEndpoint = .bitcoinCash, transactionDetails: Bool, apiKey: String)
    case fee(endpoint: BlockchairEndpoint = .bitcoinCash, apiKey: String)
    case send(txHex: String, endpoint: BlockchairEndpoint = .bitcoinCash, apiKey: String)
    case findErc20Tokens(address: String, apiKey: String)
    
    var baseURL: URL {
        var endpointString = ""
        
        switch self {
        case .address(_, let endpoint, _, _):
            endpointString = endpoint.rawValue
        case .fee(let endpoint, _):
            endpointString = endpoint.rawValue
        case .send(_, let endpoint, _):
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
        case .fee:
            return "/stats"
        case .send:
            return "/push/transaction"
        case .findErc20Tokens(address: let address, _):
            return "/dashboards/address/\(address)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address, .fee, .findErc20Tokens:
            return .get
        case .send:
            return .post
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
        case .fee(_, let apiKey):
            key = apiKey
        case .send(let txHex, _, let apiKey):
            key = apiKey
            parameters["data"] = txHex
        case .findErc20Tokens(address: let address, apiKey: let apiKey):
            key = apiKey
            parameters["erc_20"] = "true"
        }
        parameters["key"] = key
        return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
    }
    
    var headers: [String: String]? {
        switch self {
        case .address, .fee, .findErc20Tokens:
            return ["Content-Type": "application/json"]
        case .send:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        }
    }
}
