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

/// The Safe address a joint account's wallets are built at: nil until the account is active, although
/// `JointAccountStatus.confirming` carries the address already, and nil for an untrusted account.
protocol JointAccountSafeAddressProvider {
    var safeAddress: String? { get }
    var safeAddressPublisher: AnyPublisher<String?, Never> { get }
}

// MARK: - JointAccountSafeAddressProvider protocol conformance

extension JointAccountStatusProvider {
    var safeAddress: String? {
        status.activeSafeAddress
    }

    var safeAddressPublisher: AnyPublisher<String?, Never> {
        statusPublisher
            .map(\.activeSafeAddress)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

extension JointAccountStatus {
    var activeSafeAddress: String? {
        switch self {
        case .active(let safeAddress): EVMAddressUtils.toChecksumAddress(safeAddress) ?? safeAddress
        case .pending, .confirming, .untrusted, .cancelled, .unknown: nil
        }
    }
}
