//
//  JointAccountSafeAddressProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

/// The Safe address a joint account's wallets are built at: nil until the account is active, although
/// `JointAccountStatus.confirming` carries the address already, and nil for an untrusted account.
protocol JointAccountSafeAddressProvider {
    var safeAddress: String? { get }
    var safeAddressPublisher: AnyPublisher<String?, Never> { get }
}

struct JointAccountsRepositorySafeAddressProvider {
    private let cryptoAccountId: String
    private let jointAccountsRepository: JointAccountsRepository

    init(
        userWalletId: UserWalletId,
        derivationIdentity: CryptoAccountDerivationIdentity,
        jointAccountsRepository: JointAccountsRepository,
    ) {
        self.jointAccountsRepository = jointAccountsRepository
        cryptoAccountId = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString
    }

    private func safeAddress(in storedJointAccounts: [StoredJointAccount]) -> String? {
        guard
            let storedJointAccount = storedJointAccounts.first(by: cryptoAccountId),
            let statusSafeAddress = safeAddress(of: storedJointAccount.status)
        else {
            return nil
        }

        return EVMAddressUtils.toChecksumAddress(statusSafeAddress) ?? statusSafeAddress
    }

    private func safeAddress(of status: JointAccountStatus) -> String? {
        switch status {
        case .active(let safeAddress): safeAddress
        case .pending, .confirming, .untrusted, .cancelled, .unknown: nil
        }
    }
}

// MARK: - JointAccountSafeAddressProvider protocol conformance

extension JointAccountsRepositorySafeAddressProvider: JointAccountSafeAddressProvider {
    var safeAddress: String? {
        safeAddress(in: jointAccountsRepository.jointAccounts)
    }

    var safeAddressPublisher: AnyPublisher<String?, Never> {
        jointAccountsRepository
            .jointAccountsPublisher
            .map { safeAddress(in: $0) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
