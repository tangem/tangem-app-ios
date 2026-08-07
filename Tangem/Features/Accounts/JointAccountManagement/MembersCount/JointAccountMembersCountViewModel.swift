//
//  JointAccountMembersCountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class JointAccountMembersCountViewModel: ObservableObject {
    private let creationHelper: JointAccountCreationHelper
    private weak var coordinator: JointAccountMembersCountRoutable?

    init(
        creationHelper: JointAccountCreationHelper,
        coordinator: JointAccountMembersCountRoutable?
    ) {
        self.creationHelper = creationHelper
        self.coordinator = coordinator
    }

    func onContinueTap() {
        coordinator?.continueMembersCount()
    }

    func onCloseTap() {
        coordinator?.closeMembersCount()
    }
}
