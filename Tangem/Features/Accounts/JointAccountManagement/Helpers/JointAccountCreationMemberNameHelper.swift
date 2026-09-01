//
//  JointAccountCreationMemberNameHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

/// The member name step as the creation flow uses it: the name is the creator's own, and submitting it is the last
/// thing the account needs to be created.
struct JointAccountCreationMemberNameHelper {
    private let creationHelper: JointAccountCreationHelper
    private weak var routable: JointAccountCreationMemberNameRoutable?

    init(creationHelper: JointAccountCreationHelper, routable: JointAccountCreationMemberNameRoutable?) {
        self.creationHelper = creationHelper
        self.routable = routable
    }
}

// MARK: - JointAccountMemberNameHelper

extension JointAccountCreationMemberNameHelper: JointAccountMemberNameHelper {
    var submitButtonTitle: String { Localization.commonCreateAccount }

    /// Filled in when the step is returned to, so a name typed once does not have to be typed again.
    var initialName: String { creationHelper.creatorName ?? "" }

    var tangemIconProvider: TangemIconProvider { creationHelper.tangemIconProvider }

    var hasUnsavedChanges: Bool { creationHelper.hasUnsavedChanges }

    func submit(name: String) async throws(AccountEditError) {
        creationHelper.update(creatorName: name)
        let jointAccount = try await creationHelper.createAccount()

        let routable = routable

        await MainActor.run {
            routable?.openInviteMembers(jointAccount: jointAccount)
        }
    }
}

// MARK: - Routable

protocol JointAccountCreationMemberNameRoutable: AnyObject {
    func openInviteMembers(jointAccount: any JointAccountModel)
}
