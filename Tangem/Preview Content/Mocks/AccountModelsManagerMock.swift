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

    private var cryptoAccounts: [CryptoAccountModelMock] = [] {
        didSet {
            accountModelsSubject.send([.standard(.init(accounts: cryptoAccounts))])
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

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        accountModelsSubject.eraseToAnyPublisher()
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountModelsManagerError) {
        cryptoAccounts.append(CryptoAccountModelMock(isMainAccount: false))
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        return [
            ArchivedCryptoAccountInfo(
                accountId: .init(rawValue: UUID().uuidString),
                name: "Archived crypto account #1",
                icon: .init(name: .allCases.randomElement()!, color: .allCases.randomElement()!),
                tokensCount: 3,
                networksCount: 1,
                derivationIndex: 10
            ),
            ArchivedCryptoAccountInfo(
                accountId: .init(rawValue: UUID().uuidString),
                name: "Archived crypto account #2",
                icon: .init(name: .allCases.randomElement()!, color: .allCases.randomElement()!),
                tokensCount: 10,
                networksCount: 10,
                derivationIndex: 20
            ),
        ]
    }

    func archiveCryptoAccount(
        withIdentifier identifier: some AccountModelPersistentIdentifierConvertible
    ) async throws(AccountModelsManagerError) {
        removeCryptoAccount(withIdentifier: identifier.toPersistentIdentifier().toAnyHashable())
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountModelsManagerError) {
        do {
            let persistentConfig = info.toPersistentConfig()
            let isMainAccount = AccountModelUtils.isMainAccount(persistentConfig.derivationIndex)
            let unarchivedCryptoAccount = CryptoAccountModelMock(isMainAccount: isMainAccount)

            try await unarchivedCryptoAccount.setIcon(info.icon)
            try await unarchivedCryptoAccount.setName(info.name)
            cryptoAccounts.append(unarchivedCryptoAccount)
        } catch {
            throw .cannotUnarchiveCryptoAccount
        }
    }
}
