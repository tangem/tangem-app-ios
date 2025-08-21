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

class FileEncryptionUtility {
    private let keychain: SecureStorage = .init()

    init() {}

    private var keychainKey: String { "tangem_files_symmetric_key" }

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

    private func storedSymmetricKey() throws -> SymmetricKey {
        if let key = try keychain.get(keychainKey) {
            let symmetricKey: SymmetricKey = .init(data: key)
            return symmetricKey
        }

        let key = SymmetricKey(size: .bits256)
        try keychain.store(key.dataRepresentation, forKey: keychainKey)
        return key
    }
}

extension ContiguousBytes {
    /// For some reason when working with CryptoKit.SymmetricKey the data returned through `dataRepresentation` can
    /// sometimes be rubbish with a bunch of random zeros. This is a hack to stop that from happening.
    var dataRepresentationWithHexConversion: Data {
        Data(hexString: dataRepresentation.hexString)
    }
}
