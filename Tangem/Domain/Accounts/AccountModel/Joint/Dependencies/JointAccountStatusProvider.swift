//
//  JointAccountStatusProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol JointAccountStatusProvider: JointAccountSafeAddressProvider {
    var status: JointAccountStatus { get }
    var statusPublisher: AnyPublisher<JointAccountStatus, Never> { get }
}

struct CommonJointAccountStatusProvider {
    private let cryptoAccountId: String
    private let jointAccountsRepository: JointAccountsRepository
    private let userRoleService: JointAccountUserRoleService

    init(
        userWalletId: UserWalletId,
        derivationIdentity: CryptoAccountDerivationIdentity,
        jointAccountsRepository: JointAccountsRepository,
        userRoleService: JointAccountUserRoleService
    ) {
        cryptoAccountId = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString
        self.jointAccountsRepository = jointAccountsRepository
        self.userRoleService = userRoleService
    }

    private func status(in storedJointAccounts: [StoredJointAccount]) -> JointAccountStatus {
        guard let storedJointAccount = storedJointAccounts.first(by: cryptoAccountId) else {
            return .unknown
        }

        guard let ownAddress = userRoleService.ownAddress else {
            return storedJointAccount.status
        }

        let isMember = storedJointAccount.members.contains { $0.address.caseInsensitiveEquals(to: ownAddress) }
        return isMember ? storedJointAccount.status : .untrusted
    }
}

// MARK: - JointAccountStatusProvider protocol conformance

extension CommonJointAccountStatusProvider: JointAccountStatusProvider {
    var status: JointAccountStatus {
        status(in: jointAccountsRepository.jointAccounts)
    }

    var statusPublisher: AnyPublisher<JointAccountStatus, Never> {
        jointAccountsRepository
            .jointAccountsPublisher
            .map { status(in: $0) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
