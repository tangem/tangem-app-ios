//
//  BlockchainInfoEndpoint.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

public enum BlockchainInfoEndpoint: BtcEndpoint {
    case address(address:String)
    case unspents(address: String)
    case send(txHex: String)
    
        public var url: String {
        switch self {
        case .unspents(let address):
            return "https://blockchain.info/unspent?active=\(address)"
        case .send(_):
           return "https://blockchain.info/pushtx"
        case .address(let address):
            return "https://blockchain.info/rawaddr/\(address)?limit=5"
        }
    }
    
    public var testUrl: String {
        return url
    }
    
    public var method: String {
        switch self {
        case .unspents(_):
            return "GET"
        case .send(_):
            return "POST"
        case .address(_):
            return "GET"
        }
    }
    
    public var body: Data? {
        switch self {
        case .send(let txHex):
            let params = "tx=\(txHex)"
            let body = params.data(using: .utf8)
            return body
        default:
            return nil
        }
    }
    
    public var headers: [String : String] {
        return ["application/x-www-form-urlencoded":"Content-Type"]
    }
}
