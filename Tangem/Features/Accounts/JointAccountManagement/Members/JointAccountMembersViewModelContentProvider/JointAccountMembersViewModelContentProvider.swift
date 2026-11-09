//
//  JointAccountMembersViewModelContentProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol JointAccountMembersViewModelContentProvider: AnyObject {
    var titlePublisher: AnyPublisher<JointAccountMembersViewModel.Title, Never> { get }
    var slotsPublisher: AnyPublisher<[JointAccountMembersViewSlotViewModel], Never> { get }
    var footerPublisher: AnyPublisher<String?, Never> { get }
    var actionsPublisher: AnyPublisher<[JointAccountMembersViewModel.Action], Never> { get }
}
