//
//  CollectiblesState.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation

/// Reconciled on-chain state of the user's collectibles vault for a single user wallet.
public enum CollectiblesState: Hashable, Sendable {
    /// No resolve has succeeded yet — unknown is not the same thing as "no vault".
    case unresolved

    /// No vault exists on chain for this wallet's cold owner address.
    case notOnboarded

    /// The account's key isn't derived, so the vault PDA can't be computed — on-chain existence is unknown, not absent.
    case coldOwnerNotDerived

    /// A vault exists, but its `session_key` matches no local key (reinstall, new device); exits via an `update_vault` re-key.
    case rekeyRequired(CollectiblesVaultInfo)

    /// Vault is live and the active local session key matches `session_key`.
    case ready(CollectiblesVaultInfo)
}

public extension CollectiblesState {
    /// Whether a read confirmed the vault on chain. `rekeyRequired` counts — the vault is there, it just names
    /// another key. Not the same question as "does this wallet have an account": a state that read nothing yet
    /// answers no here, while the app can still know the answer from what it recorded earlier.
    var isAccountVisible: Bool {
        switch self {
        case .ready, .rekeyRequired: true
        case .unresolved, .notOnboarded, .coldOwnerNotDerived: false
        }
    }
}

/// Domain representation of the on-chain `Vault` account (legacy buyback fields omitted).
public struct CollectiblesVaultInfo: Hashable, Sendable {
    /// Base58 address of the vault PDA.
    public let vaultAddress: String

    /// Current on-chain session key (32-byte ed25519 public key).
    public let sessionKey: Data

    /// Spending caps in base USDC units (6 decimals); the program checks them against `amount + fee`.
    public let perSpinCap: UInt64
    public let dailyCap: UInt64

    /// Spent amount within the `dayIndex` UTC day bucket, rolled over lazily by the program.
    public let spentToday: UInt64

    /// UTC day bucket index, `floor(unix_time / 86400)`.
    public let dayIndex: Int64

    public init(
        vaultAddress: String,
        sessionKey: Data,
        perSpinCap: UInt64,
        dailyCap: UInt64,
        spentToday: UInt64,
        dayIndex: Int64
    ) {
        self.vaultAddress = vaultAddress
        self.sessionKey = sessionKey
        self.perSpinCap = perSpinCap
        self.dailyCap = dailyCap
        self.spentToday = spentToday
        self.dayIndex = dayIndex
    }

    /// Remaining daily budget in base USDC units. NOT `dailyCap - spentToday` — the day bucket rolls over
    /// lazily and a cap lowered mid-day can leave `spentToday` above it; never subtract the raw fields.
    public func remainingToday(now: Date) -> UInt64 {
        CollectiblesVaultProgram.SpendingMath.remainingToday(
            dailyCap: dailyCap,
            spentToday: spentToday,
            dayIndex: dayIndex,
            now: now
        )
    }
}
