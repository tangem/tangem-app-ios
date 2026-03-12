//
//  AccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemPay

protocol AccountModelsManager: AccountModelsReordering, DisposableEntity {
    /// Indicates whether the user can add more additional (not `Main`) crypto accounts to the wallet.
    var canAddCryptoAccounts: Bool { get }

    var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> { get }

    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> { get }

    var accountModels: [AccountModel] { get }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> { get }

    /// Archived + active
    var totalCryptoAccountsCountPublisher: AnyPublisher<Int, Never> { get }

    /// - Note: This method is also responsible for moving custom tokens into the newly created account if they have a matching derivation.
    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountEditError) -> AccountOperationResult

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo]

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult

    func acceptTangemPayOffer(authorizingInteractor: PaymentAccountAuthorizing) async
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
                case .tangemPay:
                    return []
                case .virtualAccount:
                    return []
                }
            }
    }

    /// Returns all crypto account models from the `accountModelsPublisher` property.
    var cryptoAccountModelsPublisher: AnyPublisher<[any CryptoAccountModel], Never> {
        accountModelsPublisher.map { accountModels in
            accountModels.flatMap { accountModel -> [any CryptoAccountModel] in
                switch accountModel {
                case .standard(.single(let cryptoAccountModel)): [cryptoAccountModel]
                case .standard(.multiple(let cryptoAccountModels)): cryptoAccountModels
                case .tangemPay: []
                case .virtualAccount: []
                }
            }
        }
        .eraseToAnyPublisher()
    }

    var tangemPayAccountModel: (any TangemPayAccountModel)? {
        let tangemPayAccountModels = accountModels
            .compactMap { accountModel in
                if case .tangemPay(let model) = accountModel {
                    return model
                }
                return nil
            }
        assert(tangemPayAccountModels.count < 2)
        return tangemPayAccountModels.first
    }

    var tangemPayAccountModelPublisher: AnyPublisher<(any TangemPayAccountModel)?, Never> {
        accountModelsPublisher
            .map { accountModels -> (any TangemPayAccountModel)? in
                let tangemPayAccountModels = accountModels
                    .compactMap { accountModel -> (any TangemPayAccountModel)? in
                        switch accountModel {
                        case .standard, .virtualAccount:
                            nil
                        case .tangemPay(let model):
                            model
                        }
                    }
                assert(tangemPayAccountModels.count < 2)
                return tangemPayAccountModels.first
            }
            .eraseToAnyPublisher()
    }

    var virtualAccountModel: (any VirtualAccountModel)? {
        let virtualAccountModels = accountModels
            .compactMap { accountModel in
                if case .virtualAccount(let model) = accountModel {
                    return model
                }
                return nil
            }
        assert(virtualAccountModels.count < 2)
        return virtualAccountModels.first
    }

    var virtualAccountModelPublisher: AnyPublisher<(any VirtualAccountModel)?, Never> {
        accountModelsPublisher
            .map { accountModels -> (any VirtualAccountModel)? in
                let virtualAccountModels = accountModels
                    .compactMap { accountModel -> (any VirtualAccountModel)? in
                        switch accountModel {
                        case .standard:
                            nil
                        case .tangemPay:
                            nil
                        case .virtualAccount(let model):
                            model
                        }
                    }
                assert(virtualAccountModels.count < 2)
                return virtualAccountModels.first
            }
            .eraseToAnyPublisher()
    }
}
