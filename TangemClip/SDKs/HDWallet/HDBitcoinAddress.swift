//
//  HDBitcoinAddress.swift
//  BlockchainSdkClips
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public enum HDAddressType {
    case pubkeyHash
    case scriptHash
    case wif
    case testnet
    
    public func addressPrefix(for coin: Coin) -> UInt8 {
        switch self {
        case .pubkeyHash:
            return coin.publicKeyHash
        case .scriptHash:
            return coin.scriptHash
        case .wif:
            return coin.wifAddressPrefix
        case .testnet:
            return coin.testnetAddressPrefix
        }
    }
}

public protocol AddressProtocol {
    var coin: Coin { get }
    var type: HDAddressType { get }
    var data: Data { get }
    
    var base58: String { get }
    var cashaddr: String { get }
}

public typealias HDAddress = AddressProtocol

public enum AddressError: Error {
    case invalid
    case invalidScheme
    case invalidVersionByte
}

public struct LegacyAddress: HDAddress {
    public let coin: Coin
    public let type: HDAddressType
    public let data: Data
    public let base58: Base58Check
    public let cashaddr: String
    
    public typealias Base58Check = String
    
    public init(_ base58: Base58Check, coin: Coin) throws {
        let raw = Data(Base58.bytesFromBase58(base58))
        let checksum = raw.suffix(4)
        let pubKeyHash = raw.dropLast(4)
        let checksumConfirm = pubKeyHash.doubleSha256.prefix(4)
        guard checksum == checksumConfirm else {
            throw AddressError.invalid
        }
        self.coin = coin
        
        let type: HDAddressType
        let addressPrefix = pubKeyHash[0]
        switch addressPrefix {
        case coin.publicKeyHash:
            type = .pubkeyHash
        case coin.wifAddressPrefix:
            type = .wif
        case coin.scriptHash:
            type = .scriptHash
        default:
            throw AddressError.invalidVersionByte
        }
        
        self.type = type
        self.data = pubKeyHash.dropFirst()
        self.base58 = base58
        
        // cashaddr
        switch type {
        case .pubkeyHash:
            let payload = Data([coin.publicKeyHash]) + self.data
            self.cashaddr = Bech32.encode(payload, prefix: coin.scheme)
        case .wif:
            let payload = Data([coin.wifAddressPrefix]) + self.data
            self.cashaddr = Bech32.encode(payload, prefix: coin.scheme)
        default:
            self.cashaddr = ""
        }
    }
    
    /// Initialize Legacy bitcoin address
    /// - Parameters:
    ///   - hash: This can be `Script` or wallet public key hash (sha256)
    ///   - coin: Target blockchain
    ///   - addressType: Type of address: `pubkeyHash`, `scriptHash`, `wif`
    public init(hash: Data, coin: Coin, addressType: HDAddressType) {
        let ripemd160Hash = RIPEMD160.hash(message: hash)
        let addressPrefixByte = addressType.addressPrefix(for: coin)
        let entendedRipemd160Hash = Data([addressPrefixByte]) + ripemd160Hash
        let sha = entendedRipemd160Hash.doubleSha256
        let checksum = sha[..<4]
        let ripemd160HashWithChecksum = entendedRipemd160Hash + checksum
        let base58 = Base58.base58FromBytes(ripemd160HashWithChecksum.bytes)
        
        self.coin = coin
        self.type = addressType
        self.data = sha
        self.base58 = base58
        
        switch addressType {
        case .pubkeyHash:
            let payload = Data([coin.publicKeyHash]) + self.data
            self.cashaddr = Bech32.encode(payload, prefix: coin.scheme)
        case .wif:
            let payload = Data([coin.wifAddressPrefix]) + self.data
            self.cashaddr = Bech32.encode(payload, prefix: coin.scheme)
        default:
            self.cashaddr = ""
        }
    }
}
