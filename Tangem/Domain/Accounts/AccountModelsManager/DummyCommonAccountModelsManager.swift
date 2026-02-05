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
        false
    }

    var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        .just(output: accountModels.count)
    }

    var accountModels: [AccountModel] {
        []
    }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        AnyPublisher.just(output: accountModels)
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountEditError) -> AccountOperationResult {
        throw .unknownError(NSError.dummy)
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        []
    }

    func archiveCryptoAccount(
        withIdentifier identifier: any AccountModelPersistentIdentifierConvertible
    ) throws(AccountArchivationError) {
        throw .unknownError(NSError.dummy)
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) throws(AccountRecoveryError) -> AccountOperationResult {
        throw .unknownError(NSError.dummy)
    }

    func reorder(orderedIdentifiers: [any AccountModelPersistentIdentifierConvertible]) async throws {
        throw NSError.dummy
    }

    func dispose() {}
}
