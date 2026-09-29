//
//  TonConnectSigner.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Ed25519 signer for the connected TON account.
///
/// Every TON Connect signature (transaction, `ton_proof`, `signData`) is a plain Ed25519 signature over a
/// 32-byte digest, which is exactly what the Tangem card / mobile wallet SDK produce for TON today.
/// The app supplies the implementation (card session, mobile wallet); the core never sees a private key.
public protocol TonConnectSigner: Sendable {
    /// Returns the 64-byte Ed25519 signature of `digest` made with the account's key.
    func sign(digest: Data) async throws -> Data
}
