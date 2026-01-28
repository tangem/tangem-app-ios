//
//  ArchivedCryptoAccountInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
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

// MARK: - CustomStringConvertible protocol conformance

extension ArchivedCryptoAccountInfo: CustomStringConvertible {
    var description: String {
        objectDescription(
            String(describing: Self.self),
            userInfo: [
                "name": name,
                "icon": icon,
                "id": id,
                "derivationIndex": derivationIndex,
                "counters": "\(tokensCount) tokens, \(networksCount) networks",
            ]
        )
    }
}

// MARK: - CryptoAccountPersistentConfigConvertible protocol conformance

extension ArchivedCryptoAccountInfo: CryptoAccountPersistentConfigConvertible {
    func toPersistentConfig() -> CryptoAccountPersistentConfig {
        return CryptoAccountPersistentConfig(
            derivationIndex: derivationIndex,
            name: name,
            icon: icon
        )
    }
}

// MARK: - Convenience extensions

extension ArchivedCryptoAccountInfo {
    func withName(_ newName: String) -> Self {
        return .init(
            accountId: accountId,
            name: newName,
            icon: icon,
            tokensCount: tokensCount,
            networksCount: networksCount,
            derivationIndex: derivationIndex
        )
    }
}

// MARK: - Analytics

extension ArchivedCryptoAccountInfo: AccountModelAnalyticsProviding {
    func analyticsParameters(with builder: AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        builder
            .setDerivationIndex(derivationIndex)
            .build()
    }
}
