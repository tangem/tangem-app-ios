//
//  JointAccountSignersViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization

/// Puts into words where every member of an account stands on one operation.
///
/// The endpoint reports only the members that answered, so the rows are laid out over the account's composition and
/// the answers matched onto it — a member it says nothing about is one still to answer.
final class JointAccountSignersViewModel: ObservableObject {
    @Published private(set) var pendingOperation: JointAccountPendingOperation
    @Published private(set) var slots: [JointAccountSlot] = []

    /// Everyone on the account, answered or not — which is also how many rows there are.
    var membersCount: Int { slots.members.count }
    var signers: [JointAccountSignerRow.ViewData] { makeSigners() }

    private weak var coordinator: JointAccountSignersRoutable?

    init(
        pendingOperation: JointAccountPendingOperation,
        handle: JointAccountPendingOperationHandle,
        coordinator: JointAccountSignersRoutable?
    ) {
        self.pendingOperation = pendingOperation
        self.coordinator = coordinator

        bind(handle: handle)
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

// MARK: - Updates

private extension JointAccountSignersViewModel {
    func bind(handle: JointAccountPendingOperationHandle) {
        handle.pendingOperationPublisher
            .compactMap { $0 }
            .receiveOnMain()
            .assign(to: &$pendingOperation)

        let slotsPublisher = pendingOperation.wallet.account?.jointAccountMembersService.slotsPublisher ?? .just(output: [])

        slotsPublisher
            .receiveOnMain()
            .assign(to: &$slots)
    }
}

// MARK: - Signers

private extension JointAccountSignersViewModel {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter
    }()

    func makeSigners() -> [JointAccountSignerRow.ViewData] {
        // Walked by slot rather than by member so the colours line up with the composition screen, which numbers
        // them the same way
        return slots.enumerated().compactMap { index, slot -> JointAccountSignerRow.ViewData? in
            guard let member = slot.member else {
                return nil
            }

            return JointAccountSignerRow.ViewData(
                id: member.address,
                icon: AddressBookContactNameIconViewData(jointAccountMember: member, at: index),
                name: member.name,
                answer: answer(of: member)
            )
        }
    }

    func answer(of member: JointAccountMember) -> JointAccountSignerRow.Answer {
        let signature = pendingOperation.signatures.first { $0.address.caseInsensitiveEquals(to: member.address) }
        let isInitiator = member.address.caseInsensitiveEquals(to: pendingOperation.initiatorAddress)

        guard let signature else {
            return .waiting
        }

        switch signature.state {
        case .signed where isInitiator:
            return .created(at: time(of: signature))
        case .signed:
            return .signed(at: time(of: signature))
        case .declined:
            return .declined
        // An answer this version cannot word is shown as none rather than as one it guessed at
        case .unknown:
            return .waiting
        }
    }

    func time(of signature: JointAccountOperation.Signature) -> String {
        guard let date = RelativeDateFormatter.shared.parseDate(from: signature.at) else {
            return ""
        }

        let day = Calendar.current.isDateInToday(date) ? Localization.commonToday : Self.dayFormatter.string(from: date)
        return "\(Self.timeFormatter.string(from: date)), \(day)"
    }
}
