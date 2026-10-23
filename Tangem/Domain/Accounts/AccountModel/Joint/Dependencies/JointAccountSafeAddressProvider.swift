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

/// The Safe address of a joint account: nil until it is activated, since only `JointAccountStatus.active` carries one,
/// and nil for one whose composition does not resolve to it — see `JointAccountSafeAddressVerifier`.
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

    /// Checked on every read rather than once on activation: a member who did not activate the account never had it
    /// checked otherwise, and any refresh can bring a different address along.
    private func safeAddress(in storedJointAccounts: [StoredJointAccount]) -> String? {
        guard
            let storedJointAccount = storedJointAccounts.first(by: cryptoAccountId),
            case .active(let announcedSafeAddress) = storedJointAccount.status
        else {
            return nil
        }

        do {
            let confirmedSafeAddress = try JointAccountSafeAddressVerifier.confirm(
                announcedAddress: announcedSafeAddress,
                owners: storedJointAccount.members.map(\.address),
                threshold: storedJointAccount.threshold
            )

            return EVMAddressUtils.toChecksumAddress(confirmedSafeAddress) ?? confirmedSafeAddress
        } catch {
            JointAccountsLogger.error("The Safe of a joint account does not resolve to the composition it is stored with", error: error)
            return nil
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
