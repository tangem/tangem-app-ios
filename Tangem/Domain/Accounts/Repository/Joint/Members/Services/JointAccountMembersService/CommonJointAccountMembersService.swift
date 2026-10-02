//
//  CommonJointAccountMembersService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemSdk

/// Reads the account's composition off the wallet's store of joint accounts and invites, matched by the account's
/// identifier.
struct CommonJointAccountMembersService {
    private let cryptoAccountId: String
    private let derivationPath: DerivationPath
    private let jointAccountsRepository: JointAccountsRepository
    private let keysProvider: KeysProvider
    private let inviteLinkBuilder = JointAccountInviteLinkBuilder()

    init(
        userWalletId: UserWalletId,
        derivationIdentity: CryptoAccountDerivationIdentity,
        jointAccountsRepository: JointAccountsRepository,
        keysProvider: KeysProvider
    ) {
        self.jointAccountsRepository = jointAccountsRepository
        self.keysProvider = keysProvider
        cryptoAccountId = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString
        derivationPath = JointAccountKeyPath.derivationPath(forAccountAtIndex: derivationIdentity.derivationIndex)
    }
}

// MARK: - JointAccountMembersService protocol conformance

extension CommonJointAccountMembersService: JointAccountMembersService {
    var slots: [JointAccountSlot] {
        slots(
            from: jointAccountsRepository.jointAccounts,
            invites: jointAccountsRepository.jointAccountsInvites
        )
    }

    var slotsPublisher: AnyPublisher<[JointAccountSlot], Never> {
        Publishers.CombineLatest(
            jointAccountsRepository.jointAccountsPublisher,
            jointAccountsRepository.jointAccountsInvitesPublisher
        )
        .map { slots(from: $0, invites: $1) }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    var isCreatorDevice: Bool {
        // Having the record is the answer, not what is left in it: a creator who filled every slot at creation was
        // handed no invites and holds a record all the same
        // [REDACTED_TODO_COMMENT]
        jointAccountsRepository.jointAccountsInvites.first(by: cryptoAccountId) != nil
    }

    var ownAddress: String? {
        try? JointAccountDerivationUtils.storedDerivedKey(at: derivationPath, in: keysProvider)?.address
    }

    func requestFrequentUpdates() -> AnyCancellable {
        jointAccountsRepository.requestFrequentUpdates()
    }
}

// MARK: - Private

private extension CommonJointAccountMembersService {
    /// The taken slots first, in the order they were taken, then a free one per slot left — each with the next invite
    /// this wallet still holds, as long as they last.
    func slots(from storedJointAccounts: [StoredJointAccount], invites: [StoredJointAccountInvites]) -> [JointAccountSlot] {
        guard let storedJointAccount = storedJointAccounts.first(by: cryptoAccountId) else {
            return []
        }

        let members = storedJointAccount.members.map(JointAccountMember.init(stored:))
        let storedInvites = invites.first(by: cryptoAccountId)?.invites ?? []
        // Written out before they are dealt out, so that one that cannot be written as a link leaves the last free
        // slot without an invite rather than a slot in the middle of the list
        let unusedInvites = unused(invites: storedInvites, among: members).compactMap(invite(from:))
        // Clamped because the count and the members come as two independent fields of the same response
        let freeSlotsCount = max(0, storedJointAccount.membersCount - members.count)

        let takenSlots = members.map(JointAccountSlot.member)
        let freeSlots = (0 ..< freeSlotsCount).map { JointAccountSlot.empty(invite: unusedInvites[safe: $0]) }

        return takenSlots + freeSlots
    }

    /// - Warning: One of these goes to one person: whoever opens an invite takes the slot it holds.
    func unused(invites: [StoredJointAccountInvite], among members: [JointAccountMember]) -> [StoredJointAccountInvite] {
        let takenInviteIds = Set(members.compactMap { $0.role.inviteId?.lowercased() })

        return invites.filter { !takenInviteIds.contains($0.id.lowercased()) }
    }

    func invite(from invite: StoredJointAccountInvite) -> JointAccountInvite? {
        guard let url = inviteLinkBuilder.buildURL(invite: invite) else {
            // Says nothing of the invite itself: a log is the last place the account's access secret belongs
            JointAccountsLogger.warning("An invite of the joint account cannot be written as a link")
            return nil
        }

        return JointAccountInvite(id: invite.id, url: url)
    }
}
