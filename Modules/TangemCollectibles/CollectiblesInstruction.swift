//
//  CollectiblesInstruction.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation

/// A program instruction in plain values, so it can cross into targets that must not link SolanaSwift —
/// the app maps it into whatever the sending layer speaks.
public struct CollectiblesInstruction: Sendable {
    public struct AccountMeta: Sendable {
        /// Base58 account address.
        public let address: String
        public let isSigner: Bool
        public let isWritable: Bool
    }

    /// Base58 program id.
    public let programId: String

    /// In the exact order the program declares.
    public let accounts: [AccountMeta]

    public let data: Data
}
