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
protocol JointAccountModel: CryptoAccountModel where Editor: JointAccountModelEditor {
    var policy: JointAccountPolicy { get }

    /// How far the account has come: waiting on its members, or activated and ready to be operated.
    /// - Note: Apart from the config, which is what the account was created with and never changes.
    var status: JointAccountStatus { get }

    /// Only the slots that are taken, in the order they were taken, the creator first.
    var members: [JointAccountMember] { get }

    /// One per slot left free at creation, which is the only time they are ever handed out — see `JointAccountInvite`.
    /// - Note: Apart from the config because they are kept apart: the endpoint hands them out once and never reports
    /// them again, so re-reading the account cannot bring them back.
    /// - Warning: Count these rather than naming them wherever an account is described. An invite is the account's
    /// only access secret, so writing one into a log hands the slot it holds to whoever reads that log.
    var invites: [JointAccountInvite] { get }
}

// MARK: - Errors

/// - Note: Reported wrapped in `AccountEditError.unknownError`, so it reads for whoever opens the log rather than for
/// the user, whose alert is built from the wrapping error.
enum JointAccountModelError: String, LocalizedError {
    /// A joint account is what its members agreed to when they took their slots, so nothing about it is any one
    /// member's to change.
    case editingNotSupported

    var errorDescription: String? {
        switch self {
        case .editingNotSupported: "A joint account cannot be edited."
        }
    }
}

// MARK: - Convenience

extension JointAccountModel {
    var creator: JointAccountMember? {
        members.first { $0.role == .creator }
    }

    /// The slots an invite is still waiting to fill.
    /// - Note: Clamped because the count and the members come as two independent fields of the same response.
    var freeSlotsCount: Int {
        max(0, policy.membersCount - members.count)
    }

    /// - Note: A status this version does not know is taken to be one the account works under, since the endpoint goes
    /// on adding to the set and only these two hold the account back.
    var isAwaitingActivation: Bool {
        switch status {
        case .pending, .confirming:
            true
        case .active, .cancelled, .unknown:
            false
        }
    }

    /// Invites are handed out once, to the creator alone, so holding one is what tells the creator apart from the
    /// members they invited.
    var canInviteMembers: Bool {
        freeSlotsCount > 0 && invites.isNotEmpty
    }
}
