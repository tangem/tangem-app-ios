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

/// Reads the account's composition off the wallet's store of joint accounts, matched by the account's identifier.
struct CommonJointAccountMembersService {
    private let cryptoAccountId: String
    private let jointAccountsRepository: JointAccountsRepository
    private let userRoleService: JointAccountUserRoleService

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

    var userRole: JointAccountUserRole {
        userRoleService.role(among: slots.members)
    }

    func requestFrequentUpdates() -> AnyCancellable {
        jointAccountsRepository.requestFrequentUpdates()
    }
}

// MARK: - Private

private extension CommonJointAccountMembersService {
    /// The taken slots first, in the order they were taken, then a free one per slot left.
    func slots(from storedJointAccounts: [StoredJointAccount]) -> [JointAccountSlot] {
        guard let storedJointAccount = storedJointAccounts.first(by: cryptoAccountId) else {
            return []
        }

        let members = storedJointAccount.members.map(JointAccountMember.init(stored:))
        // Clamped because the count and the members come as two independent fields of the same response
        let freeSlotsCount = max(0, storedJointAccount.membersCount - members.count)

        let takenSlots = members.map(JointAccountSlot.member)
        let freeSlots = (0 ..< freeSlotsCount).map { _ in JointAccountSlot.empty(invite: nil) }

        return takenSlots + freeSlots
    }
}
