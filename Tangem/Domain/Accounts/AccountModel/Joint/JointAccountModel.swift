//
//  JointAccountModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// One of the wallet's own accounts as far as its name, its icon and its tokens go — what it adds is the members it is
/// shared with and the rules they operate it by.
protocol JointAccountModel: CryptoAccountModel, JointAccountOperationsServicesProviding, JointAccountMembersServiceProviding {
    /// How many slots the account was created with and how many of them have to sign for it.
    /// - Note: Stays on the account rather than moving to the members service with the composition: it is what the
    /// account was created with and never changes, whereas who fills the slots does.
    var policy: JointAccountPolicy { get }

    var jointAccountStatusProvider: any JointAccountStatusProvider { get }

    /// Adds this wallet's confirmation of the composition and the address it adds up to. The account moves on to
    /// active once every member has confirmed, which the backend decides and the listing reports.
    /// - Note: Signs `safeAddress`, the one shown to the member, and only while the status still carries it — see
    /// `JointAccountStatus.confirming`.
    /// - Returns: The status the endpoint answered with: active once this confirmation was the last one missing.
    @discardableResult
    func confirm(safeAddress: String) async throws(AccountEditError) -> JointAccountStatus
}

// MARK: - Errors

/// - Note: Reported wrapped in `AccountEditError.unknownError`, so it reads for whoever opens the log rather than for
/// the user, whose alert is built from the wrapping error.
enum JointAccountModelError: String, LocalizedError {
    /// A joint account is what its members agreed to when they took their slots, so nothing about it is any one
    /// member's to change.
    case editingNotSupported
    /// Confirmation was asked for on an account that has no address to confirm yet.
    case notReadyForConfirmation
    case addressChanged
    /// Confirmation was asked for on an account the wallet that runs it has already let go of, so there is no longer
    /// anything to carry it out — the screen it was asked from outlived the wallet it belongs to.
    case confirmationUnavailable

    var errorDescription: String? {
        switch self {
        case .editingNotSupported: "A joint account cannot be edited."
        case .notReadyForConfirmation: "The joint account is not ready to be confirmed."
        case .addressChanged: "The joint account's address changed after it was shown."
        case .confirmationUnavailable: "The joint account can no longer be confirmed."
        }
    }
}
