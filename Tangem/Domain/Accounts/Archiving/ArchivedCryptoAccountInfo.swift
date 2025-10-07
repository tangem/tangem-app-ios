//
//  ArchivedCryptoAccountInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

/// Not a full-fledged account model, just represents some info about an archived crypto account.
/// Read-only and does not support any mutable methods from the `BaseAccountModel` protocol.
struct ArchivedCryptoAccountInfo: Equatable {
    let name: String
    let icon: AccountModel.Icon
    let tokensCount: Int
    let networksCount: Int

    private let accountId: AccountId
    private let derivationIndex: Int

    init(
        accountId: AccountId,
        name: String,
        icon: AccountModel.Icon,
        tokensCount: Int,
        networksCount: Int,
        derivationIndex: Int
    ) {
        self.accountId = accountId
        self.name = name
        self.icon = icon
        self.tokensCount = tokensCount
        self.networksCount = networksCount
        self.derivationIndex = derivationIndex
    }
}

// MARK: - Identifiable protocol conformance

extension ArchivedCryptoAccountInfo: Identifiable {
    var id: AccountId {
        accountId
    }
}

// MARK: - BaseAccountModel protocol conformance

extension ArchivedCryptoAccountInfo: BaseAccountModel {
    func setIcon(_ icon: AccountModel.Icon) {
        assertionFailure("Should never be called")
    }

    func setName(_ name: String) {
        assertionFailure("Should never be called")
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        .empty
    }
}
