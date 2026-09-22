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
protocol JointAccountModel: CryptoAccountModel, JointAccountOperationsServicesProviding, JointAccountMembersServiceProviding where Editor: JointAccountModelEditor {
    /// How many slots the account was created with and how many of them have to sign for it.
    /// - Note: Stays on the account rather than moving to the members service with the composition: it is what the
    /// account was created with and never changes, whereas who fills the slots does.
    var policy: JointAccountPolicy { get }

    /// How far the account has come: waiting on its members, or activated and ready to be operated.
    var status: JointAccountStatus { get }

    /// Whether `activate()` is this wallet's to call: the creator's alone, and only once the account reports every
    /// slot taken.
    /// - Note: The address that stage is supposed to name is not part of this — an answer that omits it is the
    /// backend's to explain once the button is pressed, not a reason to leave the creator a screen that offers nothing.
    var canActivate: Bool { get }

    /// Confirms the composition and puts the account to work, which the creator alone can do.
    /// - Note: Verifies for itself that the composition resolves to the address the backend announced before anything
    /// is signed — see `JointAccountSafeAddressVerifier`.
    func activate() async throws(AccountEditError)
}

// MARK: - Errors

/// - Note: Reported wrapped in `AccountEditError.unknownError`, so it reads for whoever opens the log rather than for
/// the user, whose alert is built from the wrapping error.
enum JointAccountModelError: String, LocalizedError {
    /// A joint account is what its members agreed to when they took their slots, so nothing about it is any one
    /// member's to change.
    case editingNotSupported
    /// Activation was asked for on an account that has no address to confirm yet, or no creator among its members.
    /// - Note: The button is offered without an announced address on purpose — see `canActivate` — so the creator
    /// does reach this one, and it says the answer named no address rather than that anything is wrong with the app.
    case notReadyForActivation
    /// Activation was asked for on an account the wallet that runs it has already let go of, so there is no longer
    /// anything to carry it out — the screen it was asked from outlived the wallet it belongs to.
    case activationUnavailable

    var errorDescription: String? {
        switch self {
        case .editingNotSupported: "A joint account cannot be edited."
        case .notReadyForActivation: "The joint account is not ready to be activated."
        case .activationUnavailable: "The joint account can no longer be activated."
        }
    }
}
