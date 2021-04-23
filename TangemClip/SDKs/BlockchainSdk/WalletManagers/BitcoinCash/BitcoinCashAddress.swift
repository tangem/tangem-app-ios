//
//  BitcoinCashAddress.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct BitcoinCashAddress: HDAddress {
    public let coin: Coin
    public let type: HDAddressType
    public let data: Data
    public let base58: String
    public let cashaddr: String
    
    public init(_ cashaddr: String) throws {
        guard let decoded = Bech32.decode(cashaddr) else {
            throw AddressError.invalid
        }
        
        let raw = decoded.data
        self.cashaddr = cashaddr
        self.coin = .bitcoinCash
        
        let versionByte = raw[0]
        let hash = raw.dropFirst()
        
        guard hash.count == BitcoinCashVersionByte.getSize(from: versionByte) else {
            throw AddressError.invalidVersionByte
        }
        self.data = hash
        guard let typeBits = BitcoinCashVersionByte.TypeBits(rawValue: (versionByte & 0b01111000)) else {
            throw AddressError.invalidVersionByte
        }
        
        switch typeBits {
        case .pubkeyHash:
            type = .pubkeyHash
            base58 = publicKeyHashToAddress(Data([coin.publicKeyHash]) + data)
        case .scriptHash:
            type = .scriptHash
            base58 = publicKeyHashToAddress(Data([coin.scriptHash]) + data)
        }
    }
}
func publicKeyHashToAddress(_ hash: Data) -> String {
    let checksum =  hash.doubleSha256.prefix(4)
    let address = Base58.base58FromBytes((hash + checksum).toBytes)
    return address
}

public class BitcoinCashVersionByte {
    static let pubkeyHash160: UInt8 = PubkeyHash160().bytes
    static let scriptHash160: UInt8 = ScriptHash160().bytes
    var bytes: UInt8 {
        return type.rawValue + size.rawValue
    }
    
    public var type: TypeBits { return .pubkeyHash }
    public var size: SizeBits { return .size160 }
    
    public static func getSize(from versionByte: UInt8) -> Int {
        guard let sizeBits = SizeBits(rawValue: versionByte & 0x07) else {
            return 0
        }
        switch sizeBits {
        case .size160:
            return 20
        case .size192:
            return 24
        case .size224:
            return 28
        case .size256:
            return 32
        case .size320:
            return 40
        case .size384:
            return 48
        case .size448:
            return 56
        case .size512:
            return 64
        }
    }
    
    // First 1 bit is zero
    // Next 4bits
    public enum TypeBits: UInt8 {
        case pubkeyHash = 0
        case scriptHash = 8
    }
    
    // The least 3bits
    public enum SizeBits: UInt8 {
        case size160 = 0
        case size192 = 1
        case size224 = 2
        case size256 = 3
        case size320 = 4
        case size384 = 5
        case size448 = 6
        case size512 = 7
    }
}

public class PubkeyHash160: BitcoinCashVersionByte {
    public override var size: SizeBits { return .size160 }
    public override var type: TypeBits { return .pubkeyHash }
}
public class ScriptHash160: BitcoinCashVersionByte {
    public override var size: SizeBits { return .size160 }
    public override var type: TypeBits { return .scriptHash }
}
