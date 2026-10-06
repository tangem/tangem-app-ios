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

    /// The screen first opens on the smallest composition there is, and on every one of its members having to sign, so
    /// that whatever the creator leaves untouched is the strictest account rather than a middling one. Coming back to
    /// it opens the composition chosen before.
    @Published var membersCount: Int {
        // A composition can't require more signatures than it has members
        didSet { signersCount = min(signersCount, membersCount) }
    }

    @Published var signersCount: Int {
        didSet { keepDraft() }
    }

    var memberStates: [JointAccountMemberCircle.State] { members() }
    var membersCountRange: ClosedRange<Int> { Constants.membersCountRange }
    var signersCountRange: ClosedRange<Int> { Constants.minimumSignersCount ... membersCount }

    private let creationHelper: JointAccountCreationHelper
    private weak var coordinator: JointAccountMembersCountRoutable?

    init(
        creationHelper: JointAccountCreationHelper,
        coordinator: JointAccountMembersCountRoutable?
    ) {
        self.creationHelper = creationHelper
        self.coordinator = coordinator
        let membersCount = creationHelper.membersCount ?? Constants.membersCountRange.lowerBound
        _membersCount = Published(initialValue: membersCount)
        _signersCount = Published(initialValue: min(creationHelper.signersCount ?? membersCount, membersCount))
    }

    func onContinueTap() {
        keepDraft()
        coordinator?.continueMembersCount(creationHelper: creationHelper)
    }

    func onCloseTap() {
        guard creationHelper.hasUnsavedChanges else {
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
    func keepDraft() {
        creationHelper.update(membersCount: membersCount, signersCount: signersCount)
    }

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
