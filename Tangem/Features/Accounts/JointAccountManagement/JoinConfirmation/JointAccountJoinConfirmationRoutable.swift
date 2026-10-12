//
//  JointAccountJoinConfirmationRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol JointAccountJoinConfirmationRoutable: AnyObject {
    func confirmJoin(userWalletModel: any UserWalletModel, preview: JointAccountInvitePreview)
    func cancelJoin()
}
