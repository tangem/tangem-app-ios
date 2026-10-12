//
//  JointAccountSignersViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

/// - Note: Handed the signers already worked out. The sheet neither reads them nor keeps them in step: "someone
///   signed" arrives as a banner rather than a push, so refreshing an open screen belongs to the domain layer and
///   this only redraws on what it is given.
final class JointAccountSignersViewModel: ObservableObject, FloatingSheetContentViewModel {
    /// Everyone on the account, answered or not — which is also how many rows there are.
    let membersCount: Int
    let signers: [JointAccountSignerRow.ViewData]

    private weak var coordinator: JointAccountSignersRoutable?

    init(
        membersCount: Int,
        signers: [JointAccountSignerRow.ViewData],
        coordinator: JointAccountSignersRoutable?
    ) {
        self.membersCount = membersCount
        self.signers = signers
        self.coordinator = coordinator
    }

    /// Back steps up to the operation this list belongs to; close leaves the operation altogether. The design
    /// offers both, and they are not the same destination.
    func onBackTap() {
        coordinator?.returnToOperationFromSigners()
    }

    func onCloseTap() {
        coordinator?.closeSigners()
    }
}
