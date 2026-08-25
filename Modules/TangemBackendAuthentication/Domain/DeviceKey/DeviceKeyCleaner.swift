//
//  DeviceKeyCleaner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]

public struct DeviceKeyCleaner {
    private let privateKeyRepository: any DevicePrivateKeyRepository

    init(privateKeyRepository: some DevicePrivateKeyRepository) {
        self.privateKeyRepository = privateKeyRepository
    }

    /// Removes the device's stored private key from the Keychain.
    public func clean() {
        privateKeyRepository.removePrivateKey()
    }
}
