//
//  CryptoAccountsRepositoryStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
@testable import Tangem

final class CryptoAccountsRepositoryStub: CryptoAccountsRepository {
    private let cryptoAccountsSubject: CurrentValueSubject<[StoredCryptoAccount], Never>

    init(cryptoAccounts: [StoredCryptoAccount] = []) {
        cryptoAccountsSubject = CurrentValueSubject(cryptoAccounts)
    }

    func store(_ cryptoAccounts: [StoredCryptoAccount]) {
        cryptoAccountsSubject.send(cryptoAccounts)
    }

    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> {
        Just(true).eraseToAnyPublisher()
    }

    var cryptoAccounts: [StoredCryptoAccount] {
        cryptoAccountsSubject.value
    }

    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> {
        cryptoAccountsSubject.eraseToAnyPublisher()
    }

    var auxiliaryDataPublisher: AnyPublisher<CryptoAccountsAuxiliaryData, Never> {
        Empty().eraseToAnyPublisher()
    }

    func initialize(forUserWalletWithId userWalletId: UserWalletId) {}

    func getRemoteState() async throws -> CryptoAccountsRemoteState {
        throw "Not called by these tests"
    }

    func loadCryptoAccountsFromRemote() async throws {}

    func addNewCryptoAccount(
        withConfig config: CryptoAccountPersistentConfig,
        remoteState: CryptoAccountsRemoteState
    ) async throws -> StoredCryptoAccountsTokensDistributor.DistributionResult {
        throw "Not called by these tests"
    }

    func updateExistingCryptoAccount(
        withConfig config: CryptoAccountPersistentConfig,
        remoteState: CryptoAccountsRemoteState
    ) async throws {
        throw "Not called by these tests"
    }

    func removeCryptoAccount(withIdentifier identifier: some Hashable) async throws {
        throw "Not called by these tests"
    }

    func reorderCryptoAccounts(orderedIdentifiers: [some Hashable]) async throws {
        throw "Not called by these tests"
    }
}
