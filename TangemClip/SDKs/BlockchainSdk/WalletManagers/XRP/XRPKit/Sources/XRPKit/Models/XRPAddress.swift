//
//  XRPAddress.swift
//  AnyCodable
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

public enum XRPAddressError: Error {
    case invalidAddress
    case checksumFails
}

public struct XRPAddress {
    var rAddress: String
    var tag: UInt32?
    var isTest: Bool
    var xAddress: String {
        return XRPAddress.encodeXAddress(rAddress: self.rAddress, tag: self.tag, test: self.isTest)
    }
    
    public init(rAddress: String, tag: UInt32? = nil, isTest: Bool = false) throws {
        if !XRPSeedWallet.validate(address: rAddress) {
            throw XRPAddressError.invalidAddress
        }
        self.rAddress = rAddress
        self.tag = tag
        self.isTest = false
    }
    
    public init(xAddress: String) throws {
        guard let data = Data(base58: xAddress, alphabet:Base58String.xrpAlphabet) else {
            throw XRPAddressError.invalidAddress
        }
        let check = data.suffix(4).bytes
        let concatenated = data.prefix(31).bytes
        if concatenated.count < 23 {
            throw XRPAddressError.invalidAddress
        }
        let tagBytes = concatenated[23...]
        let flags = concatenated[22]
        let prefix = concatenated[..<2]
        let accountID = concatenated[2..<22]
        let prefixedAccountID = Data([0x00]) + accountID
        let checksum = Data(prefixedAccountID).sha256().sha256().prefix(through: 3)
        let addrrssData = prefixedAccountID + checksum
        let address = String(base58: addrrssData, alphabet:Base58String.xrpAlphabet)
                
        if check == [UInt8](Data(concatenated).sha256().sha256().prefix(through: 3)) {
            let data = Data(tagBytes)
            let _tag: UInt64 = data.withUnsafeBytes { $0.pointee }
            let tag: UInt32? = flags == 0x00 ? nil : UInt32(String(_tag))!
            
            if prefix == [0x05, 0x44] { // mainnet
                try self.init(rAddress: address, tag: tag)
                isTest = false
            } else if prefix == [0x04, 0x93] { // testnet
                try self.init(rAddress: address, tag: tag)
                isTest = true
            } else {
                throw XRPAddressError.invalidAddress
            }
        } else {
            throw XRPAddressError.checksumFails
        }
    }
    
    public static func decodeXAddress(xAddress: String) throws -> XRPAddress {
        return try self.init(xAddress: xAddress)
    }
    
    public static func encodeXAddress(rAddress: String, tag: UInt32? = nil, test: Bool = false ) -> String {
        let accountID = XRPSeedWallet.accountID(for: rAddress)
        let prefix: [UInt8] = test ? [0x04, 0x93] : [0x05, 0x44]
        let flags: [UInt8] = tag == nil ? [0x00] : [0x01]
        let tag = tag == nil ? [UInt8](UInt64(0).data) : [UInt8](UInt64(tag!).data)
        let concatenated = prefix + accountID + flags + tag
        let check = [UInt8](Data(concatenated).sha256().sha256().prefix(through: 3))
        let concatenatedCheck: [UInt8] = concatenated + check
        return String(base58: Data(concatenatedCheck), alphabet: Base58String.xrpAlphabet)
    }
}
