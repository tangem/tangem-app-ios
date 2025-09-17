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

    func archiveCryptoAccount(withIdentifier identifier: some AccountModelPersistentIdentifierConvertible) async throws(AccountModelsManagerError) {
        removeCryptoAccount(withIdentifier: identifier.toPersistentIdentifier().toAnyHashable())
    }
}
