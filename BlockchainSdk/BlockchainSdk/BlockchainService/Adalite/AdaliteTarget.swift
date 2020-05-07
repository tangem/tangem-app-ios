//
//  AdaliteTarget.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum AdaliteUrl: String {
    case url1 = "https://explorer3.adalite.io"
    case url2 = "https://nodes.southeastasia.cloudapp.azure.com"
}

enum AdaliteTarget: TargetType {
    case address(address:String, url: AdaliteUrl)
    case unspents(address: String, url: AdaliteUrl)
    case send(base64EncodedTx: String, url: AdaliteUrl)
    
    var baseURL: URL {
        switch self {
        case .address(_, let url):
            return URL(string: url.rawValue)!
        case .unspents(_, let url):
            return URL(string: url.rawValue)!
        case .send(_, let url):
            return URL(string: url.rawValue)!
        }
    }
    
    var path: String {
        switch self {
        case .address(let address, _):
            return "/api/addresses/summary/\(address)"
        case .unspents:
            return "/api/bulk/addresses/utxo"
        case .send:
            return "/api/v2/txs/signed"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .address:
            return .get
        case .unspents, .send:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .address:
            return .requestPlain
        case .unspents(let address, _):
            let data = "[\"\(address)\"]".data(using: .utf8) ?? Data()
            return .requestData(data)
        case .send(let base64EncodedTx, _):
            return .requestParameters(parameters: ["signedTx": base64EncodedTx],
                                      encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        var headers = ["Content-Type": "application/json"]
        if case .unspents = self {
            headers["charset"] = "utf-8"
        }
        return headers
    }
}
