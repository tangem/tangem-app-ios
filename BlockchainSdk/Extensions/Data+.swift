//
//  Data+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk
import Sodium
import class WalletCore.DataVector

extension Data {
    var bytes: [UInt8] {
        return Array(self)
    }

    public func leadingZeroPadding(toLength newLength: Int) -> Data {
        guard count < newLength else { return self }

        let prefix = Data(repeating: UInt8(0), count: newLength - count)
        return prefix + self
    }

    public func trailingZeroPadding(toLength newLength: Int) -> Data {
        guard count < newLength else { return self }

        let suffix = Data(repeating: UInt8(0), count: newLength - count)
        return self + suffix
    }

    func validateAsEdKey() throws {
        _ = try Curve25519.Signing.PublicKey(rawRepresentation: self)
    }

    func validateAsSecp256k1Key() throws {
        _ = try Secp256k1Key(with: self)
    }

    func asDataVector() -> DataVector {
        return DataVector(data: self)
    }

    func hashBlake2b(key: Data, outputLength: Int) -> Data? {
        guard let hash = Sodium().genericHash.hash(
            message: bytes,
            key: key.bytes,
            outputLength: outputLength
        ) else {
            return nil
        }

        return Data(hash)
    }

    func hashBlake2b(outputLength: Int) -> Data? {
        guard let hash = Sodium().genericHash.hash(
            message: bytes,
            key: nil,
            outputLength: outputLength
        ) else {
            return nil
        }

        return Data(hash)
    }

    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}

// MARK: Data + Hexadecimal

extension Data {
    init(hex: String) {
        // Use TangemSDK implementation
        self.init(hexString: hex)
    }

    func hex(_ case: Case = .lowercase) -> String {
        let format = switch `case` {
        case .lowercase: "%02x"
        case .uppercase: "%02X"
        }
        return map { String(format: format, $0) }.joined()
    }

    enum Case {
        case lowercase
        case uppercase
    }
}
