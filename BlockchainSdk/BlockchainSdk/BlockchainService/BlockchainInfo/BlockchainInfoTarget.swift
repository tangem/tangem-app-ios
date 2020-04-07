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
    case address(address:String)
    case unspents(address: String)
    case send(txHex: String)
    
    var baseURL: URL {
        return URL(string: "https://blockchain.info")!
    }
    
    var path: String {
        switch self {
        case .unspents(let address):
            return "/unspent?active=\(address)"
        case .send(_):
            return "/pushtx"
        case .address(let address):
            return "/\(address)?limit=5"
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
        case .send(let txHex):
            let params = "tx=\(txHex)"
            let body = params.data(using: .utf8)!
            return .requestData(body)
        default:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return ["application/x-www-form-urlencoded":"Content-Type"]
    }
}
