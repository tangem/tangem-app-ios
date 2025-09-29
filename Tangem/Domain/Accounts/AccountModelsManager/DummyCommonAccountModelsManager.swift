//
//  DummyCommonAccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Just a stub when there should be no accounts available (locked wallets, feature toggle is disabled, etc).
struct DummyCommonAccountModelsManager {}

// MARK: - AccountModelsManager protocol conformance

extension DummyCommonAccountModelsManager: AccountModelsManager {
    var canAddCryptoAccounts: Bool {
        return false
    }

    var hasArchivedCryptoAccounts: AnyPublisher<Bool, Never> {
        return .just(output: false)
    }

    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        .just(output: 0)
    }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        return AnyPublisher.just(output: [])
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountModelsManagerError) {
        throw .addingCryptoAccountsNotSupported
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        return []
    }

    func archiveCryptoAccount(
        withIdentifier identifier: some AccountModelPersistentIdentifierConvertible
    ) async throws(AccountModelsManagerError) {
        throw .cannotArchiveCryptoAccount
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountModelsManagerError) {
        throw .cannotUnarchiveCryptoAccount
    }
}
