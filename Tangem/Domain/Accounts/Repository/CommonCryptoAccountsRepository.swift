//
//  CommonCryptoAccountsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CommonCryptoAccountsRepository {
    // [REDACTED_TODO_COMMENT]
    private let tokenItemsRepository: TokenItemsRepository

    init(tokenItemsRepository: TokenItemsRepository) {
        self.tokenItemsRepository = tokenItemsRepository
    }
}

// MARK: - CryptoAccountsRepository protocol conformance

extension CommonCryptoAccountsRepository: CryptoAccountsRepository {
    var totalCryptoAccountsCount: Int {
        return 1 // [REDACTED_TODO_COMMENT]
    }

    var cryptoAccountModelsPublisher: AnyPublisher<[CryptoAccountModel], Never> {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    func getAccounts() -> [StoredCryptoAccount] {
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
        ]
    }

    func addCryptoAccount(_ cryptoAccountModel: CryptoAccountModel) {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - Constants

// [REDACTED_TODO_COMMENT]
/**private */ extension CommonCryptoAccountsRepository {
    enum Constants {
        static let mainAccountDerivationIndex = 0
        static let mainAccountName = "Main Account" // [REDACTED_TODO_COMMENT]
        static let mainAccountIconName = AccountModel.Icon.Name.star.rawValue
        static let mainAccountIconColor = AccountModel.Icon.Color.brightBlue.rawValue
    }
}
