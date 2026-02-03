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

    var tangemPayCustomerId: String? { get }

    /// - Note: This method is also responsible for moving custom tokens into the newly created account if they have a matching derivation.
    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountEditError) -> AccountOperationResult

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo]

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult

    func acceptTangemPayOffer(authorizingInteractor: TangemPayAuthorizing) async

    func refreshTangemPay() async

    func syncTangemPayTokens(authorizingInteractor: any TangemPayAuthorizing)
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
                }
            }
        }
        .eraseToAnyPublisher()
    }

    var tangemPayLocalStatePublisher: AnyPublisher<TangemPayLocalState, Never> {
        accountModelsPublisher
            .compactMap { accountModels -> TangemPayLocalState? in
                accountModels
                    .compactMap { accountModel in
                        switch accountModel {
                        case .standard:
                            nil
                        case .tangemPay(let state):
                            state
                        }
                    }
                    .first
            }
            .eraseToAnyPublisher()
    }
}
