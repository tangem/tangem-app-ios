//
//  CommonAccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonAccountModelsManager {
    private let cryptoAccountsRepository: CryptoAccountsRepository

    private let newCryptoAccountSubject: PassthroughSubject<CryptoAccountModel, Never> = .init()

    init(cryptoAccountsRepository: CryptoAccountsRepository) {
        self.cryptoAccountsRepository = cryptoAccountsRepository
    }

    private func initialize() {
        // [REDACTED_TODO_COMMENT]
    }

    private lazy var _accountModelsPublisher: AnyPublisher<[AccountModel], Never> = {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }()
}

// MARK: - AccountModelsManager protocol conformance

extension CommonAccountModelsManager: AccountModelsManager {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        _accountModelsPublisher
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws -> CryptoAccountModel {
        // [REDACTED_TODO_COMMENT]
        let newCryptoAccount = CommonCryptoAccountModel()

        newCryptoAccountSubject.send(newCryptoAccount)

        return newCryptoAccount
    }

    func archiveCryptoAccount(with index: Int) async throws -> CryptoAccountModel {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }
}

@available(*, deprecated, message: "Test only initializer, remove")
extension CommonAccountModelsManager {
    convenience init(userWalletId: UserWalletId) {
        self.init(
            cryptoAccountsRepository: CommonCryptoAccountsRepository(
                tokenItemsRepository: CommonTokenItemsRepository(
                    key: userWalletId.stringValue
                )
            )
        )
    }
}
