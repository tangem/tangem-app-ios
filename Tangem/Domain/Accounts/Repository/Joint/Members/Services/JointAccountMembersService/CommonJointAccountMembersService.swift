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
    private let jointAccountsRepository: JointAccountsRepository
    private let userRoleService: JointAccountUserRoleService
    private let inviteLinkBuilder = JointAccountInviteLinkBuilder()
    private let inviteIssueProcessors = OSAllocatedUnfairLock(initialState: [JointAccountMemberSlotID: InviteIssueProcessor]())

    init(
        userWalletId: UserWalletId,
        derivationIdentity: CryptoAccountDerivationIdentity,
        jointAccountsRepository: JointAccountsRepository,
        userRoleService: JointAccountUserRoleService
    ) {
        self.jointAccountsRepository = jointAccountsRepository
        self.userRoleService = userRoleService
        cryptoAccountId = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString
    }
}

// MARK: - JointAccountMembersService protocol conformance

extension CommonJointAccountMembersService: JointAccountMembersService {
    var slots: [JointAccountSlot] {
        slots(from: jointAccountsRepository.jointAccounts)
    }

    var slotsPublisher: AnyPublisher<[JointAccountSlot], Never> {
        jointAccountsRepository.jointAccountsPublisher
            .map { slots(from: $0) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func requestFrequentUpdates() -> AnyCancellable {
        jointAccountsRepository.requestFrequentUpdates()
    }

    func issueInvite(slot: JointAccountMemberSlotID) async throws(JointAccountInviteIssueError) -> JointAccountInvite {
        let processor = inviteIssueProcessors.withLock { processors in
            if let processor = processors[slot] {
                return processor
            }

            let processor = InviteIssueProcessor()
            processors[slot] = processor

            return processor
        }

        return try await processor.execute { await issueInviteResult(slot: slot) }.get()
    }
}

// MARK: - Invites

private extension CommonJointAccountMembersService {
    typealias InviteIssueProcessor = SingleTaskProcessor<Result<JointAccountInvite, JointAccountInviteIssueError>, Never>

    func issueInviteResult(slot: JointAccountMemberSlotID) async -> Result<JointAccountInvite, JointAccountInviteIssueError> {
        do throws(JointAccountInviteIssueError) {
            let invite = try await requestInvite(slot: slot)
            return .success(invite)
        } catch {
            return .failure(error)
        }
    }

    func requestInvite(slot: JointAccountMemberSlotID) async throws(JointAccountInviteIssueError) -> JointAccountInvite {
        let issuedInvite: JointAccountIssuedInvite

        do {
            issuedInvite = try await jointAccountsRepository.issueInvite(cryptoAccountId: cryptoAccountId, slot: slot)
        } catch let error as TangemAPIError where Constants.slotUnavailableCodes.contains(error.code) {
            // The slot was taken, the account left the pending stage or this wallet is not the creator any more, all
            // of which happened in another wallet: the screen still draws the slot as free until the next poll, so
            // the account is read again now rather than leaving the stale slot on screen for the polling interval
            try? await jointAccountsRepository.loadJointAccountsFromRemote()
            throw .slotUnavailable
        } catch {
            throw .failed(error)
        }

        let url: URL

        do {
            url = try inviteLinkBuilder.buildURL(inviteId: issuedInvite.id)
        } catch {
            JointAccountsLogger.warning("An invite of the joint account cannot be written as a link")
            throw .unexpectedResponse
        }

        return JointAccountInvite(id: issuedInvite.id, url: url, expiresAt: issuedInvite.expiresAt)
    }
}

// MARK: - Private

private extension CommonJointAccountMembersService {
    func slots(from storedJointAccounts: [StoredJointAccount]) -> [JointAccountSlot] {
        guard let account = storedJointAccounts.first(by: cryptoAccountId) else {
            return []
        }

        let slotsCount = max(account.membersCount, account.members.count)
        let slotsIds = (0 ..< slotsCount).map(JointAccountMemberSlotID.init)
        let isCreator = userRoleService.isCreator ?? false

        return slotsIds.map { slot(for: $0, in: account, isCreator: isCreator) }
    }

    func slot(for slotID: JointAccountMemberSlotID, in account: StoredJointAccount, isCreator: Bool) -> JointAccountSlot {
        if let storedMember = account.member(at: slotID) {
            let member = JointAccountMember(stored: storedMember, isMe: isMe(storedMember))
            let type = memberType(of: storedMember, status: account.status)

            return .member(member, type)
        }

        guard isCreator else {
            return .empty(slotID, .notInvitable)
        }

        if let previousInvite = account.invites.first(where: { $0.slot == slotID }) {
            return .empty(slotID, .reinvitable(previousInviteExpiresAt: previousInvite.expiresAt))
        }

        return .empty(slotID, .invitable)
    }

    func isMe(_ stored: StoredJointAccount.Member) -> Bool {
        (try? userRoleService.isMe(member: stored)) == true
    }

    func memberType(of stored: StoredJointAccount.Member, status: JointAccountStatus) -> JointAccountSlot.MemberType {
        if case .active = status {
            return .active
        }

        if stored.signature != nil {
            return .confirmed
        }

        if case .confirming = status {
            return .awaitingConfirmation
        }

        return .joined
    }
}

// MARK: - StoredJointAccount+

private extension StoredJointAccount {
    func member(at slot: JointAccountMemberSlotID) -> Member? {
        guard members.allSatisfy({ $0.slot != nil }) else {
            return members[safe: slot.rawValue]
        }

        return members.first { $0.slot == slot }
    }
}

// MARK: - Constants

private extension CommonJointAccountMembersService {
    enum Constants {
        static let slotUnavailableCodes: Set<TangemAPIError.ErrorCode> = [.forbidden, .notFound, .conflict]
    }
}
