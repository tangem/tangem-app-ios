//
//  JointAccountStatus.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemMacro

/// Only ever moves forward.
/// - Note: Read off the wire by `JointAccountsNetworkMapper`, which is where the endpoint's names are matched and an
/// activated account is refused without its address; a stored record keeps whole cases, payloads included.
@RawCaseName
@CaseFlagable
enum JointAccountStatus: Equatable, Codable {
    /// No address until every slot is taken.
    case pending
    /// Every slot taken and the address computed; the members check it and the creator activates.
    /// - Note: Carries the address the backend says the composition resolves to, which is what activating confirms.
    /// Announced rather than settled: nothing is deployed at it yet, and it is only worth acting on once the app has
    /// worked out the same address itself — see `JointAccountSafeAddressVerifier`.
    /// - Note: Optional, though the contract has the address by this stage: an answer that omits it costs the one
    /// account its activation, which is where it is missed, rather than the whole list its refresh.
    case confirming(safeAddress: String?)
    /// Operated already — activation is what hands the account the address, so an active account always carries one.
    case active(safeAddress: String)
    /// Named by the contract as a place to grow into; nothing puts an account here yet.
    case cancelled
    /// One the endpoint learnt to report after this version shipped, costing itself alone rather than the whole
    /// answer — the backend goes on adding to the set.
    case unknown
}

// MARK: - CustomStringConvertible protocol conformance

extension JointAccountStatus: CustomStringConvertible {
    var description: String { rawCaseValue }
}
