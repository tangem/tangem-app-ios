//
//  JointAccountSafeAddressProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// The Safe address of a joint account: nil until it is activated, since only `JointAccountStatus.active` carries one.
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
        guard case .active(let safeAddress) = storedJointAccounts.first(by: cryptoAccountId)?.status else {
            return nil
        }

        return safeAddress
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
