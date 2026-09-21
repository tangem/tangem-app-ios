//
//  CollectiblesSessionKeySigner.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation

/// Signs spins with the vault's session key — a standalone key from device entropy, deliberately not
/// derived from the wallet's seed: its loss is recovered by an `update_vault` re-key, not a backup.
public protocol CollectiblesSessionKeySigner: AnyObject {
    /// Creates a fresh key, replacing whatever was held. The key is stored before the ceremony that names it
    /// on chain — a crash in between would otherwise strand a vault whose `session_key` nobody holds.
    func generateKey() async throws -> Data

    /// The held key's public part; `nil` when the device holds none.
    func publicKey() async throws -> Data?

    func signSpin(_ message: Data) async throws -> Data
}
