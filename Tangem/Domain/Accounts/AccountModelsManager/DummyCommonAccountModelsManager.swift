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

    var hasArchivedCryptoAccounts: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        .just(output: 0)
    }

    var accountModels: [AccountModel] {
        []
    }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        AnyPublisher.just(output: [])
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountModelsManagerError) {
        throw .addingCryptoAccountsNotSupported
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        []
    }

    func archiveCryptoAccount(
        withIdentifier identifier: any AccountModelPersistentIdentifierConvertible
    ) throws(AccountArchivationError) {
        throw .unknownError(NSError.dummy)
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) throws(AccountRecoveryError) {
        throw .unknownError(NSError.dummy)
    }
}
