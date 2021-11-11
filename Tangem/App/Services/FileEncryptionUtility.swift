//
//  FileEncryptionUtility.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import KeychainSwift

class FileEncryptionUtility {
    
    private let keychain: KeychainSwift
    
    init(keychain: KeychainSwift) {
        self.keychain = keychain
    }
    
    private var keychainKey: String { "tangem_files_symmetric_key" }
    
    func encryptData(_ data: Data) throws -> Data {
        let sealedBox = try ChaChaPoly.seal(data, using: storedSymmetricKey())
        let sealedData = sealedBox.combined
        return sealedData
    }
    
    func decryptData(_ data: Data) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: storedSymmetricKey())
        return decryptedData
    }
    
    private func storedSymmetricKey() -> SymmetricKey {
        if let key = keychain.getData(keychainKey) {
            let symmetricKey: SymmetricKey = .init(data: key)
            return symmetricKey
        }
        
        let key = SymmetricKey(size: .bits256)
        keychain.set(key.dataRepresentation, forKey: keychainKey)
        return key
    }
    
}

extension ContiguousBytes {
    /// A Data instance created safely from the contiguous bytes without making any copies.
    var dataRepresentation: Data {
        return self.withUnsafeBytes { bytes in
            let cfdata = CFDataCreateWithBytesNoCopy(nil, bytes.baseAddress?.assumingMemoryBound(to: UInt8.self), bytes.count, kCFAllocatorNull)
            return ((cfdata as NSData?) as Data?) ?? Data()
        }
    }
}
