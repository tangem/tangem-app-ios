//
//  JointAccountMembersViewSlotViewModelDelegate.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol JointAccountMembersViewSlotViewModelDelegate: AnyObject {
    func jointAccountMembersViewSlotViewModelDidTap(_ viewModel: JointAccountMembersViewSlotViewModel)
    func jointAccountMembersViewSlotViewModelDidTapInvite(_ viewModel: JointAccountMembersViewSlotViewModel) async
}
