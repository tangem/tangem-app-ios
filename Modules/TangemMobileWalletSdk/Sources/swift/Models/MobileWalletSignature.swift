//
//  MobileWalletSignature.swift
//  TangemMobileWalletSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A single signature produced by the mobile wallet, tagged with the hash it signs and the public key it
/// belongs to. The signing API returns these in input order (one per `SignData` hash), so a caller maps
/// each entry straight to its own signature instead of re-pairing signatures with hashes by position.
public struct MobileWalletSignature: Hashable {
    public let publicKey: Data
    public let hash: Data
    public let signature: Data
}
