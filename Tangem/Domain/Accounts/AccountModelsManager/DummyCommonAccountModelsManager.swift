//
//  DummyCommonAccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemPay

/// Just a stub when there should be no accounts available (locked wallets, feature toggle is disabled, etc).
struct DummyCommonAccountModelsManager {}

// MARK: - AccountModelsManager protocol conformance

extension DummyCommonAccountModelsManager: AccountModelsManager {
    var canAddCryptoAccounts: Bool {
        false
    }

    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }

    var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> {
        .just(output: false)
    }

    var totalCryptoAccountsCountPublisher: AnyPublisher<Int, Never> {
        .just(output: accountModels.count)
    }

    var totalJointAccountsCountPublisher: AnyPublisher<Int, Never> {
        .just(output: 0)
    }

    var accountModels: [AccountModel] {
        []
    }

    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        AnyPublisher.just(output: accountModels)
    }

    func addCryptoAccount(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountCreationResult {
        throw .unknownError(NSError.dummy)
    }

    func addJointAccount(context: JointAccountCreationContextType) async throws(AccountEditError) -> AccountCreationResult {
        throw .unknownError(NSError.dummy)
    }

    func joinJointAccount(context: JointAccountJoinContext) async throws(AccountEditError) -> AccountCreationResult {
        throw .unknownError(NSError.dummy)
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        []
    }

    func archiveCryptoAccount(
        withIdentifier identifier: any AccountModelPersistentIdentifierConvertible
    ) throws(AccountArchivationError) {
        throw .unknownError(NSError.dummy)
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) throws(AccountRecoveryError) -> AccountOperationResult {
        throw .unknownError(NSError.dummy)
    }

    func reloadAccountsFromRemote() async {}

    func reorder(orderedIdentifiers: [any AccountModelPersistentIdentifierConvertible]) async throws {
        throw NSError.dummy
    }

    func dispose() {}

    func acceptTangemPayOffer(authorizingInteractor: any TangemPayAuthorizing) async throws(TangemPayAuthorizationError) {}

    func acceptTangemPayCampaignOffer(
        authorizingInteractor: any TangemPayAuthorizing,
        campaignKey: String
    ) async throws(TangemPayCampaignOfferError) {}
}
