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
    private let derivationIdentity: CryptoAccountDerivationIdentity
    private let cryptoAccountId: String
    private let jointAccountsRepository: JointAccountsRepository
    private let cryptoAccountsRepository: CryptoAccountsRepository
    private let userRoleService: JointAccountUserRoleService

    init(
        userWalletId: UserWalletId,
        derivationIdentity: CryptoAccountDerivationIdentity,
        jointAccountsRepository: JointAccountsRepository,
        cryptoAccountsRepository: CryptoAccountsRepository,
        userRoleService: JointAccountUserRoleService
    ) {
        self.derivationIdentity = derivationIdentity
        cryptoAccountId = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString
        self.jointAccountsRepository = jointAccountsRepository
        self.cryptoAccountsRepository = cryptoAccountsRepository
        self.userRoleService = userRoleService
    }

    private func status(
        in storedJointAccounts: [StoredJointAccount],
        storedCryptoAccounts: [StoredCryptoAccount]
    ) -> JointAccountStatus {
        guard let storedJointAccount = storedJointAccounts.first(by: cryptoAccountId) else {
            return .unknown
        }

        guard let ownAddress = userRoleService.ownAddress else {
            return storedJointAccount.status
        }

        let isMember = storedJointAccount.members.contains { $0.address.caseInsensitiveEquals(to: ownAddress) }

        guard isMember else {
            return .untrusted
        }

        guard case .active(let safeAddress) = storedJointAccount.status else {
            return storedJointAccount.status
        }

        guard let config = signedConfig(of: storedJointAccount, in: storedCryptoAccounts),
              JointAccountConfirmationSignatureVerifier.allMembersConfirmed(
                  config: config,
                  safeAddress: safeAddress,
                  members: storedJointAccount.members
              )
        else {
            JointAccountsLogger.warning("A joint account is active but its members did not all sign its configuration, blocking it")
            return .untrusted
        }

        return storedJointAccount.status
    }

    private func signedConfig(
        of storedJointAccount: StoredJointAccount,
        in storedCryptoAccounts: [StoredCryptoAccount]
    ) -> JointAccountSignedConfig? {
        guard let storedCryptoAccount = storedCryptoAccounts.first(where: { $0.derivationIdentity == derivationIdentity }),
              let name = storedCryptoAccount.name
        else {
            return nil
        }

        return JointAccountSignedConfig(
            name: name,
            icon: storedCryptoAccount.icon.iconName,
            iconColor: storedCryptoAccount.icon.iconColor,
            membersCount: storedJointAccount.membersCount,
            threshold: storedJointAccount.threshold
        )
    }
}

// MARK: - JointAccountStatusProvider protocol conformance

extension CommonJointAccountStatusProvider: JointAccountStatusProvider {
    var status: JointAccountStatus {
        status(in: jointAccountsRepository.jointAccounts, storedCryptoAccounts: cryptoAccountsRepository.cryptoAccounts)
    }

    var statusPublisher: AnyPublisher<JointAccountStatus, Never> {
        jointAccountsRepository
            .jointAccountsPublisher
            .combineLatest(cryptoAccountsRepository.cryptoAccountsPublisher)
            .map { status(in: $0, storedCryptoAccounts: $1) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
