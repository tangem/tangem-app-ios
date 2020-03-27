//
//  BlockchairTarget.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import Moya

enum BlockchairEndpoint: String {
    case bitcoinCash = "bitcoin-cash"
}

enum BlockchairTarget: TargetType {
    private var apiKey: String {
        return "A___0Shpsu4KagE7oSabrw20DfXAqWlT"
    }
    
    case address(address:String, endpoint: BlockchairEndpoint = .bitcoinCash)
    case fee(endpoint: BlockchairEndpoint = .bitcoinCash)
    case send(txHex: String, endpoint: BlockchairEndpoint = .bitcoinCash)
    
    var baseURL: URL {
        var endpointString = ""
        
        switch self {
        case .address(_, let endpoint):
            endpointString = endpoint.rawValue
        case .fee(let endpoint):
            endpointString = endpoint.rawValue
        case .send(_, let endpoint):
            endpointString = endpoint.rawValue
        }
        
        return URL(string: "https://api.blockchair.com/\(endpointString)")!
    }
    
    var path: String {
        switch self {
        case .address(let address, _):
            return "/dashboards/address/\(address)"
        case .fee:
            return "/stats"
        case .send:
            return "/push/transaction"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address, .fee:
            return .get
        case .send:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .address:
            return .requestParameters(parameters: ["transaction_details" : "true", "key" : apiKey], encoding: URLEncoding.default)
        case .fee:
            return .requestParameters(parameters: ["key" : apiKey], encoding: URLEncoding.default)
        case .send(let txHex, _):
            return .requestParameters(parameters: ["data": txHex, "key" : apiKey], encoding: URLEncoding.default)
        }
    }
    
    public var headers: [String: String]? {
        switch self {
        case .address, .fee:
            return ["Content-Type": "application/json"]
        case .send:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        }
    }

}
