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

    func addCryptoAccount() async throws -> CryptoAccountModel {
        let existingAccounts = cryptoAccounts.accounts
        let newAccount = CryptoAccountModelMock(isMainAccount: false)
        cryptoAccounts = .init(accounts: existingAccounts + [newAccount])

        return newAccount
    }

    func archiveCryptoAccount(with index: Int) async throws -> CryptoAccountModel {
        guard let account = cryptoAccounts.accounts[safe: index] else {
            throw CommonError.noData
        }

        var existingAccounts = cryptoAccounts.accounts
        existingAccounts.remove(at: index)
        cryptoAccounts = .init(accounts: existingAccounts)

        return account
    }
}

// MARK: - Convenience extensions

private extension CryptoAccounts {
    var accounts: [CryptoAccountModel] {
        switch self {
        case .single(let account):
            return [account]
        case .multiple(let accounts):
            return accounts
        }
    }
}
