//
//  JointAccountCreationContext.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

/// Accumulates the input collected by the joint account creation flow, which spans several screens,
/// until there is enough of it to actually create the account.
/// - Note: Created by [REDACTED_AUTHOR]
final class JointAccountCreationContext {
    /// Anything gathered so far is lost when the flow is left, since the account is only created by [REDACTED_AUTHOR]
    var hasUnsavedChanges: Bool {
        state.withLock { $0.formData != nil || $0.membersData != nil || $0.creatorName != nil }
    }

    var tangemIconProvider: TangemIconProvider {
        CommonTangemIconProvider(config: userWalletConfig)
    }

    private let userWalletConfig: UserWalletConfig
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(userWalletConfig: UserWalletConfig) {
        self.userWalletConfig = userWalletConfig
    }

    func update(name: String, icon: AccountModel.CompositeIcon) {
        state.withLock { $0.formData = FormData(name: name, icon: icon) }
    }

    func update(membersCount: Int, signersCount: Int) {
        state.withLock { $0.membersData = MembersData(membersCount: membersCount, signersCount: signersCount) }
    }

    /// The name is stored as it was typed, `JointAccountMemberNameValidator` is what decides whether it fits.
    func update(creatorName: String) {
        state.withLock { $0.creatorName = creatorName }
    }
}

// MARK: - Auxiliary types

private extension JointAccountCreationContext {
    struct State {
        var formData: FormData?
        var membersData: MembersData?
        var creatorName: String?
    }

    struct FormData {
        let name: String
        let icon: AccountModel.CompositeIcon
    }

    struct MembersData {
        let membersCount: Int
        /// How many of the members have to sign for an operation to go through
        let signersCount: Int
    }
}
