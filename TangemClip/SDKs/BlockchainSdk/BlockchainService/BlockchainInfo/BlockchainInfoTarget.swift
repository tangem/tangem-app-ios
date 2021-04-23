//
//  BlockchainInfoTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum BlockchainInfoTarget: TargetType {
	case address(address: String, limit: Int?, offset: Int?)
    case unspents(address: String)
    case send(txHex: String)
    
    var baseURL: URL {
        return URL(string: "https://blockchain.info")!
    }
    
    var path: String {
        switch self {
        case .unspents:
            return "/unspent"
        case .send(_):
            return "/pushtx"
        case .address(let address, _, _):
            return "/rawaddr/\(address)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .unspents:
            return .get
        case .send:
            return .post
        case .address:
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case let .address(_, limit, offset):
			var params = [String:String]()
			if let limit = limit {
				params["limit"] = "\(limit)"
			}
			if let offset = offset {
				params["offset"] = "\(offset)"
			}
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
        case .unspents(let address):
            return .requestParameters(parameters: ["active": address], encoding: URLEncoding.default)
        case .send(let txHex):
            let params = "tx=\(txHex)"
            let body = params.data(using: .utf8)!
            return .requestData(body)
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .send:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
