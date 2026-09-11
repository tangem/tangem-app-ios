//
//  DevicePrivateKeyRepositoryError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// The specific reason `DevicePrivateKeyRepository` failed to produce the device's private key.
public enum DevicePrivateKeyRepositoryError: Error {
    /// Generating a new Secure Enclave key pair failed.
    case keyGenerationFailed(underlying: (any Error)?)

    /// A private key was found in the Keychain,
    /// but its stored bytes could not be turned back into a usable Secure Enclave key.
    case keyRestorationFailed(underlying: any Error)

    /// ``KeychainRepository`` operation failed.
    case keychainFailure(KeychainRepositoryError)
}
