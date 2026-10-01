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

    /// Whether this wallet is the one the account was created from.
    /// - Note: Told apart by having been handed the account's invites, which the creator alone is — the endpoint
    /// names no wallet as this one, and the wallet's own address is not known here. Having been handed them is not
    /// the same as still holding one: an account created with every slot taken comes with none at all, and its
    /// creator is the creator all the same.
    /// - Warning: The invites are kept by the device that was handed them and nowhere else, so a creator who
    /// reinstalls the app or restores the wallet elsewhere stops being told apart as one.
    var isCreatorDevice: Bool { get }

    func requestFrequentUpdates() -> AnyCancellable
}
