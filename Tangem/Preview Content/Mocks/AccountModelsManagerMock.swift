//
//  AccountModelsManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class AccountModelsManagerMock {
    private let accountModelsSubject = PassthroughSubject<[AccountModel], Never>()

    private var cryptoAccounts: CryptoAccounts = [] {
        didSet {
            accountModelsSubject.send([.standard(cryptoAccounts)])
        }
    }

    init() {
        // `defer` is used to trigger the `didSet` observer
        defer {
            let mainAccount = CryptoAccountModelMock(isMainAccount: true)
            cryptoAccounts = .single(mainAccount)
        }
    }
}

// MARK: - AccountModelsManager protocol conformance

extension AccountModelsManagerMock: AccountModelsManager {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        accountModelsSubject.eraseToAnyPublisher()
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws -> any CryptoAccountModel {
        let existingAccounts = cryptoAccounts.accounts
        let newAccount = CryptoAccountModelMock(isMainAccount: false)
        cryptoAccounts = .init(accounts: existingAccounts + [newAccount])

        return newAccount
    }

    func archiveCryptoAccount(withIdentifier identifier: some AccountModelPersistentIdentifierConvertible) async throws {
        var existingAccounts = cryptoAccounts.accounts
        existingAccounts.removeAll { $0.id.toPersistentIdentifier() == identifier.toPersistentIdentifier() }
        cryptoAccounts = .init(accounts: existingAccounts)
    }
}

// MARK: - Convenience extensions

private extension CryptoAccounts {
    var accounts: [any CryptoAccountModel] {
        switch self {
        case .single(let account):
            return [account]
        case .multiple(let accounts):
            return accounts
        }
    }
}
