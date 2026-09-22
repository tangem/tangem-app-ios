//
//  AcceptingAddressBookSignatureVerifier.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import Tangem

/// Accepts every signature, so a test can build verified entries without producing real ones.
struct AcceptingAddressBookSignatureVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool { true }
}
