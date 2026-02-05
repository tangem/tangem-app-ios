//
//  AccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol AccountModelsManager: AccountModelsReordering, DisposableEntity {
    /// Indicates whether the user can add more additional (not `Main`) crypto accounts to the wallet.
    var canAddCryptoAccounts: Bool { get }

    var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> { get }

    var accountModels: [AccountModel] { get }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> { get }

    /// Archived + active
    var totalAccountsCountPublisher: AnyPublisher<Int, Never> { get }

    /// - Note: This method is also responsible for moving custom tokens into the newly created account if they have a matching derivation.
    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountEditError) -> AccountOperationResult

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo]

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult
}

// MARK: - Convenience extensions

extension AccountModelsManager {
    /// Returns all crypto account models from the `accountModels` property.
    var cryptoAccountModels: [any CryptoAccountModel] {
        return accountModels
            .flatMap { accountModel -> [any CryptoAccountModel] in
                switch accountModel {
                case .standard(.single(let cryptoAccountModel)):
                    return [cryptoAccountModel]
                case .standard(.multiple(let cryptoAccountModels)):
                    return cryptoAccountModels
                }
            }
    }

    /// Returns all crypto account models from the `accountModelsPublisher` property.
    var cryptoAccountModelsPublisher: AnyPublisher<[any CryptoAccountModel], Never> {
        accountModelsPublisher.map { accountModels in
            accountModels.flatMap { accountModel in
                switch accountModel {
                case .standard(.single(let cryptoAccountModel)): [cryptoAccountModel]
                case .standard(.multiple(let cryptoAccountModels)): cryptoAccountModels
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
