//
//  StellarRequestOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

enum StellarEndpoint {
    case address(address:String)
    case fee
    case send(txHex: String)

    
    public var url: String {
        switch self {
        case .fee:
            return "https://horizon.stellar.org/"
        case .send(_):
            return "https://horizon.stellar.org/"
        case .address(let address):
            return "https://horizon.stellar.org/"
        }
    }
    
    public var testUrl: String {
        return url.replacingOccurrences(of: "horizon", with: "horizon-testnet")
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
    
}
