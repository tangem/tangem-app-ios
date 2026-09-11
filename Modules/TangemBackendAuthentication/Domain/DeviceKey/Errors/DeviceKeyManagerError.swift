//
//  DeviceKeyManagerError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// The way ``DeviceKeyManager`` failed to satisfy a ``DeviceKeyManager/publicKey`` or ``DeviceKeyManager/sign(data:)`` call.
public enum DeviceKeyManagerError: Error {
    /// The manager's `DevicePrivateKeyRepository` could not produce a private key.
    ///
    /// - SeeAlso: ``TangemBackendAuthentication/DevicePrivateKeyRepositoryError`` for the specific reason.
    case privateKeyUnavailable(DevicePrivateKeyRepositoryError)

    /// The private key was obtained, but deriving ``DevicePublicKey`` from it failed.
    case publicKeyConstructionFailed(DevicePublicKey.RawPointFormatError)

    /// The private key was obtained, but signing the given data with it failed.
    case signingFailed(underlying: any Error)
}
