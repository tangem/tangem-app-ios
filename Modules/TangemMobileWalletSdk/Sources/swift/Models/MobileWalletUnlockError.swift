//
//  MobileWalletUnlockError.swift
//  TangemMobileWalletSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Why an access-code unlock of a mobile wallet failed.
///
/// The two cases need different handling by the caller: a wrong code is a user error and may be counted
/// toward the lock / delete ladder, while a key-storage failure means the wallet cannot be opened with
/// ANY code (e.g. the Secure Enclave wrapping key was purged when the device passcode was turned off) and
/// must never be presented as "wrong access code" or steer the user toward deleting the wallet.
public enum MobileWalletUnlockError: Error, Equatable {
    /// The password layer rejected the access code (AES-GCM authentication failed).
    case wrongAccessCode

    /// The access code was accepted by the password layer, but the inner Secure Enclave layer could not
    /// unwrap the key. The wallet data is intact, but the SE key that protects it is gone or unusable.
    case keyStorageUnavailable
}
