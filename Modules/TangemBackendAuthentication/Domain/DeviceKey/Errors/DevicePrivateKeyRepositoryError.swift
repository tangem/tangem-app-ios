//
//  DevicePrivateKeyRepositoryError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import typealias Darwin.MacTypes.OSStatus

/// The specific reason `DevicePrivateKeyRepository` failed to produce the device's private key.
public enum DevicePrivateKeyRepositoryError: Error {
    /// Generating a new Secure Enclave key pair failed.
    case keyGenerationFailed(underlying: (any Error)?)

    /// A private key was found in the Keychain,
    /// but its stored bytes could not be turned back into a usable Secure Enclave key.
    case keyRestorationFailed(underlying: any Error)

    /// A Keychain item was found for the expected service/account, but it isn't `Foundation.Data` as expected.
    case keychainItemCorrupted

    /// Looking up the stored key in the Keychain failed.
    ///
    /// - Invariant: Never `errSecItemNotFound` — that outcome means no key exists yet, not a failure.
    case keychainQueryFailed(status: OSStatus)

    /// Persisting a newly generated key to the Keychain failed.
    case keychainSaveFailed(status: OSStatus)

    /// An untyped error that doesn't match any of the cases above.
    case unexpectedFailure(underlying: any Error)
}
