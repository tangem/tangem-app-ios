//
//  CollectiblesDevnetActions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
// and the three menu items it feeds once testers can top up on a network of their own.
protocol CollectiblesDevnetActions: AnyObject {
    /// Where USDC for the packs goes: the vault's USDC account, not the vault itself.
    func topUpAddress() async throws -> String

    /// Where devnet SOL goes: the owner key pays the fee for every transaction the onboarding signs, so an
    /// unfunded one stops it before the vault is deployed.
    func feePayerAddress() throws -> String

    func closeVault() async throws -> CollectiblesVaultCloseOutcome
}

enum CollectiblesVaultCloseOutcome {
    /// The chain stopped answering with the vault: the account is gone and everything local is cleared.
    case confirmed

    /// The transaction was accepted, but the chain still answers with the vault. It lands on its own; until a
    /// later refresh sees that, the account keeps showing up.
    case submitted
}
