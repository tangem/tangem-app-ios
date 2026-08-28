//
//  JointAccountJoinMemberNameHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

/// The member name step as the join flow uses it: the name introduces this wallet to an account somebody else made.
struct JointAccountJoinMemberNameHelper {
    private let userWalletModel: any UserWalletModel

    init(userWalletModel: any UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}

// MARK: - JointAccountMemberNameHelper

extension JointAccountJoinMemberNameHelper: JointAccountMemberNameHelper {
    var submitButtonTitle: String { Localization.jointAccountJoinToAccountBtnText }

    var initialName: String { "" }

    var tangemIconProvider: TangemIconProvider { CommonTangemIconProvider(config: userWalletModel.config) }

    /// Nothing is gathered before this step in the join flow, so leaving costs the user only the typed name.
    var hasUnsavedChanges: Bool { false }

    func submit(name: String) async throws(AccountEditError) {
        // [REDACTED_TODO_COMMENT]
    }
}
