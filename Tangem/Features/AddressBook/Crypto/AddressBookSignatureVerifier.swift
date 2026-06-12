//
//  AddressBookSignatureVerifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// Verifies entry signatures against the precomputed 32-byte digest with the wallet's secp256k1 key.
///
/// Uses the `hash:` overload, which does NOT re-hash: the digest is already
/// `SHA-256(SignedTuplePayload)`. The `message:` overload would apply SHA-256 again and every
/// signature would fail to verify.
struct AddressBookSignatureVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool {
        do {
            return try Secp256k1Signature(with: signature).verify(with: walletPublicKey, hash: digest)
        } catch {
            return false
        }
    }
}
