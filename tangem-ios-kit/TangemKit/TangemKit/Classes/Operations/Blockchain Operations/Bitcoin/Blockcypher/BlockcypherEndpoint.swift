//
//  BlockcypherEndpoint.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

public enum BlockcypherEndpoint: BtcEndpoint  {
    case address(address:String)
    case fee
    case send(txHex: String)
    
    private var randomToken: String {
        let tokens: [String] = ["aa8184b0e0894b88a5688e01b3dc1e82",
                                "56c4ca23c6484c8f8864c32fde4def8d",
                                "66a8a37c5e9d4d2c9bb191acfe7f93aa"]
        
        let tokenIndex = Int.random(in: 0...2)
        return tokens[tokenIndex]
    }
    
    public var url: String {
        switch self {
        case .fee:
            return "https://api.blockcypher.com/v1/btc/main"
        case .send(_):
            return "https://api.blockcypher.com/v1/btc/main/txs/push?token=\(randomToken)"
        case .address(let address):
            return "https://api.blockcypher.com/v1/btc/main/addrs/\(address)?unspentOnly=true&includeScript=true"
        }
    }
    
    public var testUrl: String {
        return url.replacingOccurrences(of: "main", with: "test3")
    }
    
    public var method: String {
        switch self {
        case .fee:
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
            let jsonDict = ["tx": txHex]
            let body = try? JSONSerialization.data(withJSONObject: jsonDict, options: [])
            return body
        default:
            return nil
        }
    }
    
    public var headers: [String : String] {
        return [:]
    }
}
