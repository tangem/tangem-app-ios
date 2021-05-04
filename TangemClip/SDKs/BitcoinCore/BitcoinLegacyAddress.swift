//
//  Address.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public enum BitcoinCoreAddressType: UInt8 { case pubKeyHash = 0, scriptHash = 8 }

public class BitcoinCoreLegacyAddress: Equatable {
    public let type: BitcoinCoreAddressType
    public let keyHash: Data
    public let stringValue: String

    public var lockingScript: Data {
        switch type {
        case .pubKeyHash: return OpCode.p2pkhStart + OpCode.push(keyHash) + OpCode.p2pkhFinish
        case .scriptHash: return OpCode.p2shStart + OpCode.push(keyHash) + OpCode.p2shFinish
        }
    }

    public init(type: BitcoinCoreAddressType, keyHash: Data, base58: String) {
        self.type = type
        self.keyHash = keyHash
        self.stringValue = base58
    }

    public static func == (lhs: BitcoinCoreLegacyAddress, rhs: BitcoinCoreLegacyAddress) -> Bool {
        lhs.type == rhs.type && lhs.keyHash == rhs.keyHash
    }
}
