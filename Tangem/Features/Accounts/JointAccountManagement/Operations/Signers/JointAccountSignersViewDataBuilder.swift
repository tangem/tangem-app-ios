//
//  JointAccountSignersViewDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Puts into words where every member of an account stands on one operation.
///
/// The endpoint reports only the members that answered, so the rows are laid out over the account's composition and
/// the answers matched onto it — a member it says nothing about is one still to answer.
struct JointAccountSignersViewDataBuilder {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let answerDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let answerDateFallbackFormatter = ISO8601DateFormatter()

    func build(pendingOperation: JointAccountPendingOperation) -> [JointAccountSignerRow.ViewData] {
        let operation = pendingOperation.operation
        let slots = pendingOperation.wallet.account?.jointAccountMembersService.slots ?? []

        // Walked by slot rather than by member so the colours line up with the composition screen, which numbers
        // them the same way
        return slots.enumerated().compactMap { index, slot -> JointAccountSignerRow.ViewData? in
            guard case .member(let member) = slot else {
                return nil
            }

            return JointAccountSignerRow.ViewData(
                id: member.address,
                // [REDACTED_TODO_COMMENT]
                icon: AddressBookContactNameIconViewData(
                    letter: member.name.prefix(1).uppercased(),
                    color: CompositeIconColorPalette.color(for: JointAccountInviteMembersViewModel.iconColor(at: index))
                ),
                name: member.name,
                answer: answer(of: member, in: operation)
            )
        }
    }
}

// MARK: - Private

private extension JointAccountSignersViewDataBuilder {
    func answer(of member: JointAccountMember, in operation: JointAccountOperation) -> JointAccountSignerRow.Answer {
        let signature = operation.signatures.first { $0.address.caseInsensitiveEquals(to: member.address) }
        let isInitiator = member.address.caseInsensitiveEquals(to: operation.initiator)

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
        let date = Self.answerDateFormatter.date(from: signature.at) ?? Self.answerDateFallbackFormatter.date(from: signature.at)

        return date.map(Self.timeFormatter.string(from:)) ?? ""
    }
}
