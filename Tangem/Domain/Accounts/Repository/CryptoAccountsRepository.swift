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
    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> { get }
    var auxiliaryDataPublisher: AnyPublisher<CryptoAccountsAuxiliaryData, Never> { get }

    func initialize(forUserWalletWithId userWalletId: UserWalletId)

    func getRemoteState() async throws -> CryptoAccountsRemoteState

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
