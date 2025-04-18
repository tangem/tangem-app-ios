//
//  Account.swift
//  XRPKit
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

enum SeedError: Error {
    case invalidSeed
}

enum KeyPairError: Error {
    case invalidPrivateKey
}

enum SeedType {
    case ed25519
    case secp256k1
}

protocol XRPWallet {
    var privateKey: String { get }
    var publicKey: String { get }
    var address: String { get }
    var accountID: [UInt8] { get }

    static func deriveAddress(publicKey: String) -> String
    static func accountID(for address: String) -> [UInt8]
    static func validate(address: String) -> Bool
}

extension XRPWallet {
    var accountID: [UInt8] {
        let accountID = Data(hex: publicKey).sha256Ripemd160
        return [UInt8](accountID)
    }

    /// Derive a standard XRP address from a key.
    ///
    /// - Parameter publicKey: hexadecimal key
    /// - Returns: standard XRP address encoded using XRP alphabet
    ///
    static func deriveAddress(publicKey: String) -> String {
        let accountID = Data(hex: publicKey).sha256Ripemd160
        let prefixedAccountID = Data([0x00]) + accountID
        let checksum = Data(prefixedAccountID).sha256().sha256().prefix(through: 3)
        let addrrssData = prefixedAccountID + checksum
        let address = XRPBase58.getString(from: addrrssData)
        return address
    }

    static func accountID(for address: String) -> [UInt8] {
        let decodedData = XRPBase58.getData(from: address)!
        let decodedDataWithoutCheksum = Data(decodedData.dropLast(4))
        let accountId = decodedDataWithoutCheksum.leadingZeroPadding(toLength: 20)
        return accountId.bytes
    }

    /// Validates a String is a valid XRP address.
    ///
    /// - Parameter address: address encoded using XRP alphabet
    /// - Returns: true if valid
    ///
    static func validate(address: String) -> Bool {
        if address.first != "r" {
            return false
        }
        if address.count < 25 || address.count > 35 {
            return false
        }
        if let _addressData = XRPBase58.getData(from: address) {
            let decodedDataWithoutCheksum = Data(_addressData.dropLast(4))
            let prefixedAccountId = decodedDataWithoutCheksum.leadingZeroPadding(toLength: 21)
            let checksum = [UInt8](_addressData.suffix(4))
            let _checksum = [UInt8](prefixedAccountId.sha256().sha256().prefix(4))
            if checksum == _checksum {
                return true
            }
        }
        return false
    }
}

class XRPSeedWallet: XRPWallet {
    var privateKey: String
    var publicKey: String
    var seed: String
    var address: String

    private init(privateKey: String, publicKey: String, seed: String, address: String) {
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.seed = seed
        self.address = address
    }

    static func getSeedTypeFrom(publicKey: String) -> SeedType {
        let data = Data(hexString: publicKey)
        // [REDACTED_TODO_COMMENT]
        return data.count == 33 && data[0] == 0xED ? .ed25519 : .secp256k1
    }
}
