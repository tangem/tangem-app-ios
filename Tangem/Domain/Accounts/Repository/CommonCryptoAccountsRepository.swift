//
//  CommonCryptoAccountsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonCryptoAccountsRepository {
    // [REDACTED_TODO_COMMENT]
    @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

    private let userWalletId: UserWalletId
    private let tokenItemsRepository: TokenItemsRepository
    private let networkService: CryptoAccountsService

    init(
        userWalletId: UserWalletId,
        tokenItemsRepository: TokenItemsRepository,
        networkService: CryptoAccountsService
    ) {
        self.userWalletId = userWalletId
        self.tokenItemsRepository = tokenItemsRepository
        self.networkService = networkService
    }
}

// MARK: - CryptoAccountsRepository protocol conformance

extension CommonCryptoAccountsRepository: CryptoAccountsRepository {
    var totalCryptoAccountsCount: Int {
        // [REDACTED_TODO_COMMENT]
        return 1
    }

    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> {
        // [REDACTED_TODO_COMMENT]
        return .just(output: _getAccounts())
    }

    // [REDACTED_TODO_COMMENT]
    private func _getAccounts() -> [StoredCryptoAccount] {
        // [REDACTED_TODO_COMMENT]
        return [
            StoredCryptoAccount(
                derivationIndex: Constants.mainAccountDerivationIndex,
                name: Constants.mainAccountName,
                icon: .init(
                    iconName: Constants.mainAccountIconName,
                    iconColor: Constants.mainAccountIconColor
                ),
                tokenList: tokenItemsRepository.getList()
            ),
            StoredCryptoAccount(
                derivationIndex: 1,
                name: "Test account",
                icon: .init(
                    iconName: AccountModel.Icon.Name.airplane.rawValue,
                    iconColor: AccountModel.Icon.Color.coralRed.rawValue
                ),
                tokenList: tokenItemsRepository.getList()
            ),
        ]
    }

    func initialize() {}

    func addCryptoAccount(_ cryptoAccountModel: any CryptoAccountModel) {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - Constants

// [REDACTED_TODO_COMMENT]
/** private */ extension CommonCryptoAccountsRepository {
    enum Constants {
        static let mainAccountDerivationIndex = 0
        static let mainAccountName = "Main Account" // [REDACTED_TODO_COMMENT]
        static let mainAccountIconName = AccountModel.Icon.Name.star.rawValue
        static let mainAccountIconColor = AccountModel.Icon.Color.brightBlue.rawValue
    }
}
