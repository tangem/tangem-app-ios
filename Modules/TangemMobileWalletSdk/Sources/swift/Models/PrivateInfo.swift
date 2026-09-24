//
//  PrivateInfo.swift
//  TangemMobileWalletSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public final class PrivateInfo {
    private(set) var entropy: Data

    /// Backing store for the BIP39 passphrase. Kept as `Data` (rather than a
    /// `String`) so that `clear()` can zero the plaintext bytes in place, the
    /// same way it does for `entropy`. A `String` cannot be reliably wiped.
    private(set) var passphraseData: Data

    var passphrase: String {
        String(decoding: passphraseData, as: UTF8.self)
    }

    init(entropy: Data, passphrase: String) {
        self.entropy = entropy
        passphraseData = Data(passphrase.utf8)
    }

    init(entropy: Data, passphraseData: Data) {
        self.entropy = entropy
        self.passphraseData = passphraseData
    }

    func clear() {
        entropy.secureErase()
        passphraseData.secureErase()
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

        var passphraseData = Data()
        if passphraseLength > 0 {
            guard data.count >= offset + passphraseLength else { return nil }
            passphraseData = data.subdata(in: offset ..< (offset + passphraseLength))
            offset += passphraseLength
        }

        self.init(entropy: entropy, passphraseData: passphraseData)
    }

    func encode() -> Data {
        var data = Data()
        data.append(Constants.packagingVersion)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(entropy.count).bigEndian, Array.init))
        data.append(entropy)

        data.append(contentsOf: withUnsafeBytes(of: UInt32(passphraseData.count).bigEndian, Array.init))
        data.append(passphraseData)

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
