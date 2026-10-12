//
//  CollectiblesAccountKeyPath.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

enum CollectiblesAccountKeyPath {
    /// Both ed25519 flavors derive a key at this all-hardened path, and the vault is addressed off that key,
    /// so a curve pinned here instead of taken from the wallet addresses a vault no other platform sees.
    static func curve(for config: UserWalletConfig) -> EllipticCurve {
        blockchainsVersion(for: config).ed25519Curve
    }

    /// `m/44'/501'/999700'/0'/0'` — fixed, because a wallet has at most one collectibles account.
    /// - Warning: A part of the contract with the backend and Android. The vault is addressed off the key this path
    /// produces, so changing a node orphans every vault already created, along with what it holds.
    static let derivationPath = DerivationPath(nodes: [
        .hardened(Constants.purposeNodeValue),
        .hardened(Constants.coinTypeNodeValue),
        .hardened(Constants.collectiblesAccountNodeValue),
        .hardened(0),
        .hardened(0),
    ])
}

// MARK: - Private implementation

private extension CollectiblesAccountKeyPath {
    /// Wallet 2 brought the v3 paths and slip0010 together, so the derivation style tells which generation
    /// of the blockchain list the wallet is served — the wallet itself never states it.
    static func blockchainsVersion(for config: UserWalletConfig) -> SupportedBlockchains.Version {
        switch config.derivationStyle {
        case .v3:
            return .v2
        case .v1, .v2, .none:
            return .v1
        }
    }
}

// MARK: - Constants

private extension CollectiblesAccountKeyPath {
    enum Constants {
        static let purposeNodeValue: UInt32 = 44
        static let coinTypeNodeValue: UInt32 = 501
        /// The namespace marker separating the account from ordinary Solana derivations, which are three nodes.
        static let collectiblesAccountNodeValue: UInt32 = 999_700
    }
}
