//
//  FileEncryptionUtility.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk
import TangemFoundation

/// - Note: `@unchecked Sendable` only because the stateless `SecureStorage` from TangemSdk isn't marked `Sendable`.
final class FileEncryptionUtility: @unchecked Sendable {
    private static let criticalSection = OSAllocatedUnfairLock()

    private let keychain = SecureStorage()

    func encryptData(_ data: Data) throws -> Data {
        let sealedBox = try ChaChaPoly.seal(data, using: try storedSymmetricKey())
        let sealedData = sealedBox.combined
        return sealedData
    }

    func decryptData(_ data: Data) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: try storedSymmetricKey())
        return decryptedData
    }

    func clean() {
        do {
            try Self.criticalSection {
                try keychain.delete(Constants.keychainKey)
            }
        } catch {
            AppLogger.error("Failed to clean file encryption key", error: error)
        }
    }

    private func storedSymmetricKey() throws -> SymmetricKey {
        return try Self.criticalSection {
            if let key = try keychain.get(Constants.keychainKey) {
                return SymmetricKey(data: key)
            }

            let key = SymmetricKey(size: .bits256)
            try keychain.store(key.dataRepresentation, forKey: Constants.keychainKey)

            return key
        }
    }
}

// MARK: - Constants

private extension FileEncryptionUtility {
    enum Constants {
        static let keychainKey = "tangem_files_symmetric_key"
    }
}

// MARK: - Convenience extensions

extension ContiguousBytes {
    /// For some reason when working with CryptoKit.SymmetricKey the data returned through `dataRepresentation` can
    /// sometimes be rubbish with a bunch of random zeros. This is a hack to stop that from happening.
    var dataRepresentationWithHexConversion: Data {
        Data(hexString: dataRepresentation.hexString)
    }
}
