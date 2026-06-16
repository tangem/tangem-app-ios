//
//  AddressBookSignatureVerifying.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Verifies a wallet-key signature against a precomputed 32-byte digest.
///
/// The only consumer is `AddressBookVerifiedAddressEntry.make(verifying:...)`, which is the sole construction
/// path for a `AddressBookVerifiedAddressEntry`. Implementations must verify against the *digest* directly and
/// must not re-hash it.
protocol AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool
}
