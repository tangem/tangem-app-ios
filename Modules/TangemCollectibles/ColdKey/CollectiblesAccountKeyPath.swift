//
//  CollectiblesAccountKeyPath.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
public import TangemSdk
public import BlockchainSdk
import TangemFoundation

public enum CollectiblesAccountKeyPath {
    /// Both ed25519 flavors derive a key at this all-hardened path, and the vault is addressed off that key,
    /// so a curve pinned here instead of taken from the wallet addresses a vault no other platform sees.
    ///
    /// Wallet 2 brought the v3 paths and slip0010 together, so the derivation style tells which flavor the
    /// wallet is served — the wallet itself never states it.
    public static func curve(for derivationStyle: DerivationStyle?) -> EllipticCurve {
        switch derivationStyle {
        case .v3:
            return .ed25519_slip0010
        case .v1, .v2, .none:
            return .ed25519
        }
    }

    /// `m/44'/501'/999799'/0'/0'` — fixed, because a wallet has at most one collectibles account.
    /// - Warning: A part of the contract with the backend and Android. The vault is addressed off the key this path
    /// produces, so changing a node orphans every vault already created, along with what it holds.
    public static let derivationPath = try! DerivationPath(rawPath: FeatureDerivationPaths.collectibles)
}
