//
//  CryptoAccountsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol CryptoAccountsRepository {
    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> { get }
    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> { get }
    var auxiliaryDataPublisher: AnyPublisher<CryptoAccountsAuxiliaryData, Never> { get }

    func initialize(forUserWalletWithId userWalletId: UserWalletId)

    func getRemoteState() async throws -> CryptoAccountsRemoteState

    /// Replaces the local accounts with what the backend has, which is how an account the backend adds by itself
    /// — the wallet's own entry for a joint account — reaches the list.
    func loadCryptoAccountsFromRemote() async throws

    func addNewCryptoAccount(
        withConfig config: CryptoAccountPersistentConfig,
        remoteState: CryptoAccountsRemoteState
    ) async throws -> StoredCryptoAccountsTokensDistributor.DistributionResult

    func updateExistingCryptoAccount(
        withConfig config: CryptoAccountPersistentConfig,
        remoteState: CryptoAccountsRemoteState
    ) async throws

    func removeCryptoAccount(withIdentifier identifier: some Hashable) async throws
    func reorderCryptoAccounts(orderedIdentifiers: [some Hashable]) async throws
}
