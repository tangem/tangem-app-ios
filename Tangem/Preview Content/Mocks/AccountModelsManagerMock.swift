//
//  AccountModelsManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class AccountModelsManagerMock {
    private let accountModelsSubject = PassthroughSubject<[AccountModel], Never>()
    private let totalAccountsCountSubject = PassthroughSubject<Int, Never>()

    private var cryptoAccounts: [CryptoAccountModelMock] = [] {
        didSet {
            accountModelsSubject.send([.standard(.init(accounts: cryptoAccounts))])
            totalAccountsCountSubject.send(cryptoAccounts.count)
        }
    }

    init() {
        // `defer` is used to trigger the `didSet` observer
        defer {
            let mainAccount = CryptoAccountModelMock(isMainAccount: true)
            cryptoAccounts = [mainAccount]
        }
    }

    private func removeCryptoAccount(withIdentifier identifier: AnyHashable) {
        cryptoAccounts.removeAll { $0.id.toPersistentIdentifier().toAnyHashable() == identifier }
    }
}

// MARK: - AccountModelsManager protocol conformance

extension AccountModelsManagerMock: AccountModelsManager {
    var canAddCryptoAccounts: Bool {
        true
    }

    var hasArchivedCryptoAccounts: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        totalAccountsCountSubject.eraseToAnyPublisher()
    }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        accountModelsSubject.eraseToAnyPublisher()
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountModelsManagerError) {
        cryptoAccounts.append(CryptoAccountModelMock(isMainAccount: false))
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        // [REDACTED_TODO_COMMENT]
        return []
    }

    func archiveCryptoAccount(
        withIdentifier identifier: any AccountModelPersistentIdentifierConvertible
    ) throws(AccountModelsManagerError) {
        removeCryptoAccount(withIdentifier: identifier.toPersistentIdentifier().toAnyHashable())
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) throws(AccountModelsManagerError) {
        // [REDACTED_TODO_COMMENT]
        throw .cannotUnarchiveCryptoAccount
    }
}
