//
//  VarString.swift
//  HDWalletKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Essentia. All rights reserved.
//

import Foundation

/// Variable length string can be stored using a variable length integer followed by the string itself.
public struct VarString: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public let length: VarInt
    public let value: String
    
    public init(stringLiteral value: String) {
        self.init(value)
    }
    
    public init(_ value: String) {
        self.value = value
        length = VarInt(value.data(using: .ascii)!.count)
    }
    
    public func serialized() -> Data {
        var data = Data()
        data += length.serialized()
        data += value
        return data
    }
}

extension VarString: CustomStringConvertible {
    public var description: String {
        return "\(value)"
    }
}
