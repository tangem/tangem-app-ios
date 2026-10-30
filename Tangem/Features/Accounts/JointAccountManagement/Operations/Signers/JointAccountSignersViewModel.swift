//
//  JointAccountSignersViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// - Note: Handed the signers already worked out; this only redraws on what it is given.
final class JointAccountSignersViewModel: ObservableObject {
    /// Everyone on the account, answered or not — which is also how many rows there are.
    @Published private(set) var membersCount: Int
    @Published private(set) var signers: [JointAccountSignerRow.ViewData]

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

    func update(membersCount: Int, signers: [JointAccountSignerRow.ViewData]) {
        self.membersCount = membersCount
        self.signers = signers
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
