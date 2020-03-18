//
//  BlockcypherEndpoint.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
public enum BlockcyperApi: String {
    case btc
    case ltc
    case eth
}

public enum BlockcypherEndpoint: BtcEndpoint, TokenizedEndpoint  {
    case address(address:String, api: BlockcyperApi)
    case fee(api: BlockcyperApi)
    case send(txHex: String, api: BlockcyperApi)
    case txs(txHash: String, api: BlockcyperApi)
    
    private var randomToken: String {
        let tokens: [String] = ["aa8184b0e0894b88a5688e01b3dc1e82",
                                "56c4ca23c6484c8f8864c32fde4def8d",
                                "66a8a37c5e9d4d2c9bb191acfe7f93aa"]
        
        let tokenIndex = Int.random(in: 0...2)
        return tokens[tokenIndex]
    }
    
    public var url: String {
        switch self {
        case .fee(let api):
            return "https://api.blockcypher.com/v1/\(api.rawValue)/main"
        case .send(_, let api):
            return "https://api.blockcypher.com/v1/\(api.rawValue)/main/txs/push"
        case .address(let address, let api):
            return "https://api.blockcypher.com/v1/\(api.rawValue)/main/addrs/\(address)?unspentOnly=true&includeScript=true"
        case .txs(let txHash, let api):
            return "https://api.blockcypher.com/v1/\(api.rawValue)/main/txs/\(txHash)"
        }
    }
    
    public var testUrl: String {
        return url.replacingOccurrences(of: "main", with: "test3")
    }
    
    public var tokenizedUrl: String {
        switch self {
        case .fee, .send, .txs:
            return url + "?token=\(randomToken)"
        case .address:
            return url + "&token=\(randomToken)"
        }
    }
    
    public var tokenizedTestUrl: String {
        return tokenizedUrl.replacingOccurrences(of: "main", with: "test3")
    }
    
    public var method: String {
        switch self {
        case .fee:
            return "GET"
        case .send:
            return "POST"
        case .address:
            return "GET"
        case .txs:
            return "GET"
        }
    }
    
    public var body: Data? {
        switch self {
        case .send(let txHex, _):
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
