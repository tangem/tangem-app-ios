//
//  JointAccountMembersService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// The composition of one joint account: who holds its slots and what opens the ones still free.
protocol JointAccountMembersService {
    /// What is stored at this moment — the synchronous counterpart of `slotsPublisher`.
    var slots: [JointAccountSlot] { get }

    /// Starts with the composition as it stands, then one value per change: a subscriber that draws the slots needs
    /// nothing else to draw them from.
    var slotsPublisher: AnyPublisher<[JointAccountSlot], Never> { get }

    var userRole: JointAccountUserRole { get }

    func requestFrequentUpdates() -> AnyCancellable
}
