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
    /// Every slot taken and the address computed; every member checks it and confirms it, and the backend activates
    /// the account once all of them have.
    /// - Note: Carries the address the backend says the composition resolves to, which is what each member confirms.
    /// Checked against the composition through CREATE2 when it is read off the endpoint, so the address it carries is
    /// one the app has worked out itself — see `JointAccountSafeAddressVerifier`; an address that does not resolve
    /// makes the account `untrusted` instead.
    /// - Note: Optional, though the contract has the address by this stage: an answer that omits it costs the one
    /// account its confirmation, which is where it is missed, rather than the whole list its refresh.
    case confirming(safeAddress: String?)
    /// Operated already, at the address its members confirmed, so an active account always carries one.
    case active(safeAddress: String)
    /// The backend named an address the composition does not resolve to through CREATE2, so the account is not the one
    /// it claims to be and is neither confirmed nor operated — see `JointAccountSafeAddressVerifier`.
    case untrusted
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
