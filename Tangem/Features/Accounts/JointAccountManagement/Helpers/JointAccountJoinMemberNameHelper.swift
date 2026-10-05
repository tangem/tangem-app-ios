//
//  JointAccountJoinMemberNameHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

/// The member name step as the join flow uses it: the name introduces this wallet to an account somebody else made,
/// and submitting it signs the invited terms and takes the slot.
struct JointAccountJoinMemberNameHelper {
    private let inviteId: String
    private let signedConfig: JointAccountSignedConfig
    private let userWalletModel: any UserWalletModel
    private weak var routable: JointAccountJoinMemberNameRoutable?

    init(
        inviteId: String,
        signedConfig: JointAccountSignedConfig,
        userWalletModel: any UserWalletModel,
        routable: JointAccountJoinMemberNameRoutable?
    ) {
        self.inviteId = inviteId
        self.signedConfig = signedConfig
        self.userWalletModel = userWalletModel
        self.routable = routable
    }
}

// MARK: - JointAccountMemberNameHelper

extension JointAccountJoinMemberNameHelper: JointAccountMemberNameHelper {
    var submitButtonTitle: String { Localization.jointAccountJoinToAccountBtnText }

    var initialName: String { "" }

    var tangemIconProvider: TangemIconProvider { CommonTangemIconProvider(config: userWalletModel.config) }

    /// Nothing is gathered before this step in the join flow, so leaving costs the user only the typed name.
    var hasUnsavedChanges: Bool { false }

    /// The join flow has no earlier step to return to, so there is nowhere to keep the name.
    func keepDraft(name: String) {}

    func submit(name: String) async throws(AccountEditError) {
        let context = JointAccountJoinContext(
            inviteId: inviteId,
            signedConfig: signedConfig,
            memberName: name
        )

        // The identity the slot was taken under is of no use here: the flow closes and the account arrives with the list
        _ = try await userWalletModel.accountModelsManager.joinJointAccount(context: context)

        let routable = routable

        await MainActor.run {
            routable?.closeJoinedAccount()
        }
    }
}

// MARK: - Routable

protocol JointAccountJoinMemberNameRoutable: AnyObject {
    /// Leaves the flow once the slot is taken — the account shows up in the wallet on its own.
    func closeJoinedAccount()
}
