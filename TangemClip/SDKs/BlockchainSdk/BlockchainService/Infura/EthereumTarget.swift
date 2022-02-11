//
//  EthereumProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import TangemSdk

enum EthereumTarget: TargetType {
    static let infuraTokenId = 03
    static let coinId = 67
    
    case balance(address: String, url: URL)
    case tokenBalance(address: String, contractAddress: String, url: URL)
    
    var baseURL: URL {
        switch self {
        case .balance(_, let url): return url
        case .tokenBalance(_, _, let url): return url
        }
    }
    
    var path: String {
        return ""
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var sampleData: Data { Data() }
    
    var task: Task {
        var parameters: [String: Any] = [
            "jsonrpc": "2.0",
            "method": ethMethod,
            "id": EthereumTarget.coinId
        ]
        
        var params: [Any] = []
        switch self {
        case .balance(let address, _):
            params.append(address)
        case .tokenBalance(let address, let contractAddress, _):
            let rawAddress = address.removeHexPrefix()
            let dataValue = ["data": "0x70a08231000000000000000000000000\(rawAddress)", "to": contractAddress]
            params.append(dataValue)
        }
        
        if let blockParams = blockParams {
            params.append(blockParams)
        }
        parameters["params"] = params
        
        return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
    
    var headers: [String : String]? {
        return ["Content-Type": "application/json"]
    }
    
    private var ethMethod: String {
        switch self {
        case .balance: return "eth_getBalance"
        case .tokenBalance: return "eth_call"
        }
    }
    
    private var blockParams: String? {
        switch self {
        case .balance, .tokenBalance: return "latest"
        }
    }
}
