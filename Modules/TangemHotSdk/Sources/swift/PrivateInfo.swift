//
//  PrivateInfo.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public final class PrivateInfo {
    private(set) var entropy: Data
    let passphrase: String

    public init(entropy: Data, passphrase: String) {
        self.entropy = entropy
        self.passphrase = passphrase
    }

    func clear() {
        secureErase(data: &entropy)
    }
}

/// Encoding / decoding for PrivateInfo
extension PrivateInfo {
    convenience init?(data: Data) {
        guard data.count > 1 else { return nil }

        var offset = 0
        // Check packaging version
        let version = data[offset]

        // Validate packaging version
        guard version == Constants.packagingVersion else { return nil }

        offset += 1
        guard data.count >= offset + 4 else { return nil }
        // Read entropy size
        let entropySize = Int(UInt32(bigEndian: data.subdata(in: offset ..< (offset + 4)).withUnsafeBytes { $0.load(as: UInt32.self) }))

        // Validate entropy size
        offset += 4
        guard data.count >= offset + entropySize else { return nil }
        let entropy = data.subdata(in: offset ..< (offset + entropySize))

        offset += entropySize

        // Read passphrase length
        guard data.count >= offset + 4 else { return nil }
        let passphraseLength = Int(UInt32(bigEndian: data.subdata(in: offset ..< (offset + 4)).withUnsafeBytes { $0.load(as: UInt32.self) }))
        offset += 4

        var passphrase: String = ""
        if passphraseLength > 0 {
            guard data.count >= offset + passphraseLength else { return nil }
            let passphraseBytes = data.subdata(in: offset ..< (offset + passphraseLength))
            passphrase = String(decoding: passphraseBytes, as: UTF8.self)
            offset += passphraseLength
        }

        self.init(entropy: entropy, passphrase: passphrase)
    }

    func encode() -> Data {
        var data = Data()
        data.append(Constants.packagingVersion)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(entropy.count).bigEndian, Array.init))
        data.append(entropy)

        let passphraseCount = UInt32(passphrase.count)
        data.append(contentsOf: withUnsafeBytes(of: passphraseCount.bigEndian, Array.init))

        if let passphraseBytes = passphrase.data(using: .utf8), !passphraseBytes.isEmpty {
            data.append(contentsOf: passphraseBytes)
        }

        return data
    }
}

extension PrivateInfo {
    enum Constants {
        static let packagingVersion: UInt8 = 1
    }
}

enum PrivateInfoError: Error {
    case invalidData
}
