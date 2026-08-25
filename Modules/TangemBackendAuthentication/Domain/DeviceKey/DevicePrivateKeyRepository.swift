//
//  DevicePrivateKeyRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Produces and removes the `DevicePrivateKey` a ``DeviceKeyManager`` should use, loading or generating it as needed.
///
/// The only production implementation is `SecureEnclaveDevicePrivateKeyRepository`,
/// which loads a previously stored key from the Keychain or generates and persists a new one.
protocol DevicePrivateKeyRepository<Key>: Sendable {
    associatedtype Key: DevicePrivateKey

    var privateKey: Key { get throws(DevicePrivateKeyRepositoryError) }
    func removePrivateKey()
}
