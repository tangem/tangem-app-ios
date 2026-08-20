//
//  JointAccountMembersCountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct TangemUIUtils.AlertBinder

final class JointAccountMembersCountViewModel: ObservableObject {
    @Published var alert: AlertBinder?

    @Published var membersCount: Int = 3 {
        // A composition can't require more signatures than it has members
        didSet { signersCount = min(signersCount, membersCount) }
    }

    @Published var signersCount: Int = 2

    var memberStates: [JointAccountMemberCircle.State] { members() }
    var membersCountRange: ClosedRange<Int> { Constants.membersCountRange }
    var signersCountRange: ClosedRange<Int> { Constants.minimumSignersCount ... membersCount }

    private let creationContext: JointAccountCreationHelper
    private weak var coordinator: JointAccountMembersCountRoutable?

    init(
        creationContext: JointAccountCreationHelper,
        coordinator: JointAccountMembersCountRoutable?
    ) {
        self.creationContext = creationContext
        self.coordinator = coordinator
    }

    func onContinueTap() {
        creationContext.update(membersCount: membersCount, signersCount: signersCount)
        coordinator?.continueMembersCount(creationContext: creationContext)
    }

    func onCloseTap() {
        guard creationContext.hasUnsavedChanges else {
            coordinator?.closeMembersCount()
            return
        }

        alert = JointAccountExitAlert.make { [weak self] in
            self?.coordinator?.closeMembersCount()
        }
    }
}

// MARK: - Private

private extension JointAccountMembersCountViewModel {
    func members() -> [JointAccountMemberCircle.State] {
        (0 ..< Constants.membersCountRange.upperBound).map { index -> JointAccountMemberCircle.State in
            switch index {
            case ..<signersCount: .active
            case ..<membersCount: .filled
            default: .empty
            }
        }
    }
}

// MARK: - Constants

private extension JointAccountMembersCountViewModel {
    enum Constants {
        static let membersCountRange = 2 ... 5
        static let minimumSignersCount = 1
    }
}
