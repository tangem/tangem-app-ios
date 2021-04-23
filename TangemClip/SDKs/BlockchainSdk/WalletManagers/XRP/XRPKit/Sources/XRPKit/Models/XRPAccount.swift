//
//  XRPAccount.swift
//  BigInt
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public struct XRPAccount: Codable {
    public var address: String
    public var secret: String
    
    public init(address: String, secret: String) {
        self.address = address
        self.secret = secret
    }
}
