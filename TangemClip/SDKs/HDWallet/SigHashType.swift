//
//  SigHashType.swift
//  BlockchainSdkClips
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

private let SIGHASH_ALL: UInt8 = 0x01 // 00000001
private let SIGHASH_NONE: UInt8 = 0x02 // 00000010
private let SIGHASH_SINGLE: UInt8 = 0x03 // 00000011
private let SIGHASH_FORK_ID: UInt8 = 0x40 // 01000000
private let SIGHASH_ANYONECANPAY: UInt8 = 0x80 // 10000000

private let SIGHASH_OUTPUT_MASK: UInt8 = 0x1f // 00011111

public struct SighashType {
    private(set) public var uint8: UInt8
    init(_ uint8: UInt8) {
        self.uint8 = uint8
    }
    
    private var outputType: UInt8 {
        return self.uint8 & SIGHASH_OUTPUT_MASK
    }
    public var isAll: Bool {
        return outputType == SIGHASH_ALL
    }
    public var isSingle: Bool {
        return outputType == SIGHASH_SINGLE
    }
    public var isNone: Bool {
        return outputType == SIGHASH_NONE
    }
    
    public var hasForkId: Bool {
        return (self.uint8 & SIGHASH_FORK_ID) != 0
    }
    public var isAnyoneCanPay: Bool {
        return (self.uint8 & SIGHASH_ANYONECANPAY) != 0
    }
    
    public struct BCH {
        public static let ALL: SighashType = SighashType(SIGHASH_FORK_ID + SIGHASH_ALL) // 01000001
        public static let NONE: SighashType = SighashType(SIGHASH_FORK_ID + SIGHASH_NONE) // 01000010
        public static let SINGLE: SighashType = SighashType(SIGHASH_FORK_ID + SIGHASH_SINGLE) // 01000011
        public static let ALL_ANYONECANPAY: SighashType = SighashType(SIGHASH_FORK_ID + SIGHASH_ALL + SIGHASH_ANYONECANPAY) // 11000001
        public static let NONE_ANYONECANPAY: SighashType = SighashType(SIGHASH_FORK_ID + SIGHASH_NONE + SIGHASH_ANYONECANPAY) // 11000010
        public static let SINGLE_ANYONECANPAY: SighashType = SighashType(SIGHASH_FORK_ID + SIGHASH_SINGLE + SIGHASH_ANYONECANPAY) // 11000011
    }
    
    public struct BTC {
        public static let ALL: SighashType = SighashType(SIGHASH_ALL) // 0000 0001
        public static let NONE: SighashType = SighashType(SIGHASH_NONE) // 0000 0010
        public static let SINGLE: SighashType = SighashType(SIGHASH_SINGLE) // 0000 0011
        public static let ANYONECANPAY: SighashType = SighashType(SIGHASH_ANYONECANPAY) // 1000 0000
        public static let ALL_ANYONECANPAY: SighashType = SighashType(SIGHASH_ALL + SIGHASH_ANYONECANPAY) // 1000 0001
        public static let NONE_ANYONECANPAY: SighashType = SighashType(SIGHASH_NONE + SIGHASH_ANYONECANPAY) // 1000 0010
        public static let SINGLE_ANYONECANPAY: SighashType = SighashType(SIGHASH_SINGLE + SIGHASH_ANYONECANPAY) // 1000 0011
    }
    
    static func hashTypeForCoin(coin: Coin) -> SighashType {
        switch coin {
        case .bitcoinCash:
            return BCH.ALL
        default:
            return BTC.ALL
        }
    }
}

extension UInt8 {
    public init(_ hashType: SighashType) {
        self = hashType.uint8
    }
}

extension UInt32 {
    public init(_ hashType: SighashType) {
        self = UInt32(UInt8(hashType))
    }
}
