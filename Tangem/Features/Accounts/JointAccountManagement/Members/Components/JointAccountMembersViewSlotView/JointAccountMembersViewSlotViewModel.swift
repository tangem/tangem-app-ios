//
//  JointAccountMembersViewSlotViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization

final class JointAccountMembersViewSlotViewModel: ObservableObject, Identifiable {
    let slot: JointAccountSlot
    let icon: JointAccountMemberIconViewData

    @Published private(set) var isLoading = false

    private let expiryFormatter: JointAccountInviteExpiryFormatter
    private var inviteRequest: Task<Void, Error>?
    private weak var delegate: JointAccountMembersViewSlotViewModelDelegate?

    init(
        slot: JointAccountSlot,
        index: Int,
        expiryFormatter: JointAccountInviteExpiryFormatter,
        delegate: JointAccountMembersViewSlotViewModelDelegate
    ) {
        self.slot = slot
        self.expiryFormatter = expiryFormatter
        self.delegate = delegate
        icon = JointAccountMemberIconViewData(slot: slot, index: index)
    }

    var id: ID {
        switch slot {
        case .member(let member, _): .member(address: member.address.lowercased())
        case .empty(let id, _): .freeSlot(id)
        }
    }

    var title: String {
        switch slot {
        case .member(let member, _): member.name
        case .empty: Localization.jointAccountInviteMembersMember
        }
    }

    var subtitle: Subtitle {
        switch slot {
        case .member(let member, _): .plain(roleText(of: member))
        case .empty(_, .notInvitable): .plain(Localization.jointAccountInviteMembersWaitingToJoin)
        case .empty(_, .invitable): .plain(Localization.jointAccountInviteMembersNotInvited)
        case .empty(_, .reinvitable(let expiresAt)): inviteSubtitle(expiresAt: expiresAt)
        }
    }

    var accessory: Accessory {
        switch slot {
        case .member(_, .joined): .joined
        case .member(_, .awaitingConfirmation): .notConfirmed
        case .member(_, .confirmed): .confirmed
        case .member(_, .active): .empty
        case .empty(_, .notInvitable): .empty
        case .empty(_, .invitable): .invite
        case .empty(_, .reinvitable): .reInvite
        }
    }

    var contentKey: ContentKey {
        ContentKey(title: title, subtitle: subtitle, accessory: accessory)
    }

    var isTappable: Bool {
        switch slot {
        case .member: true
        case .empty: false
        }
    }

    func onTap() {
        guard isTappable else {
            return
        }

        delegate?.jointAccountMembersViewSlotViewModelDidTap(self)
    }

    func onInviteTap() {
        switch accessory {
        case .invite, .reInvite:
            guard inviteRequest == nil else {
                return
            }

            inviteRequest = runWithDelayedLoading(onLongRunning: { [weak self] in
                self?.isLoading = true
            }, operation: { [weak self] in
                await self?.requestInvite()
            })
        case .empty, .joined, .confirmed, .notConfirmed:
            break
        }
    }
}

// MARK: - Private

private extension JointAccountMembersViewSlotViewModel {
    func roleText(of member: JointAccountMember) -> String {
        let text = switch member.role {
        case .creator: Localization.jointAccountInviteMembersCreator
        case .member: Localization.jointAccountInviteMembersMember
        }

        return member.isMe ? "\(text) \(AppConstants.dotSign) \(Localization.jointAccountMembersRoleYou)" : text
    }

    func inviteSubtitle(expiresAt: Date) -> Subtitle {
        guard expiryFormatter.isExpired(expiresAt) else {
            return .plain(expiryFormatter.untilText(expiresAt: expiresAt))
        }

        return .expiry(Localization.jointAccountInviteMembersInviteExpired)
    }

    @MainActor
    func requestInvite() async {
        defer {
            isLoading = false
            inviteRequest = nil
        }

        await delegate?.jointAccountMembersViewSlotViewModelDidTapInvite(self)
    }
}

// MARK: - Auxiliary types

extension JointAccountMembersViewSlotViewModel {
    enum ID: Hashable {
        case member(address: String)
        case freeSlot(JointAccountMemberSlotID)
    }

    struct ContentKey: Hashable {
        let title: String
        let subtitle: Subtitle
        let accessory: Accessory
    }

    enum Subtitle: Hashable {
        case plain(String)
        case expiry(String)

        var text: String {
            switch self {
            case .plain(let text), .expiry(let text): text
            }
        }
    }

    enum Accessory: Hashable {
        case empty
        case joined
        case confirmed
        case notConfirmed
        case invite
        case reInvite
    }
}
