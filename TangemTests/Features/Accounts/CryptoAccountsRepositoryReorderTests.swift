//
//  CryptoAccountsRepositoryReorderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CommonCryptoAccountsRepository reordering")
struct CryptoAccountsRepositoryReorderTests {
    @Test("Accounts move past an entry the reorder screen doesn't show, and the entry keeps its place")
    func reorderPassesHiddenEntry() async throws {
        let persistentStorage = PersistentStorageStub(accounts: [
            Fixtures.account(derivationIndex: 0),
            Fixtures.account(derivationIndex: 1),
            Fixtures.collectiblesAccount,
            Fixtures.account(derivationIndex: 2),
        ])
        let networkService = NetworkServiceSpy()
        let sut = makeSUT(persistentStorage: persistentStorage, networkService: networkService)

        try await sut.reorderCryptoAccounts(orderedIdentifiers: [2, 0, 1].map(Fixtures.persistentIdentifier))

        let storedOrder = persistentStorage.getList().map(\.derivationIdentity.derivationIndex)
        let savedOrder = networkService.savedAccounts.map(\.derivationIdentity.derivationIndex)

        #expect(storedOrder == [2, 0, 999799, 1])
        #expect(savedOrder == [2, 0, 999799, 1])
    }
}

// MARK: - Helpers

private extension CryptoAccountsRepositoryReorderTests {
    func makeSUT(
        persistentStorage: PersistentStorageStub,
        networkService: NetworkServiceSpy
    ) -> CommonCryptoAccountsRepository {
        CommonCryptoAccountsRepository(
            tokenItemsRepository: TokenItemsRepositoryStub(),
            defaultAccountFactory: DefaultAccountFactoryStub(),
            networkService: networkService,
            walletLifecycleObserver: WalletLifecycleObserverStub(),
            auxiliaryDataStorage: AuxiliaryDataStorageStub(),
            persistentStorage: persistentStorage,
            storageController: PersistentStorageControllerStub(),
            hasTokenSynchronization: true
        )
    }

    enum Fixtures {
        static let icon = StoredCryptoAccount.Icon(iconName: "Star", iconColor: "Azure")

        static let collectiblesAccount = StoredCryptoAccount(
            derivationIndex: 999799,
            type: .collectibles,
            name: "Collectibles",
            icon: icon,
            tokens: [],
            grouping: .none,
            sorting: .manual
        )

        static func account(derivationIndex: Int) -> StoredCryptoAccount {
            StoredCryptoAccount(
                derivationIndex: derivationIndex,
                type: .crypto,
                name: nil,
                icon: icon,
                tokens: [],
                grouping: .none,
                sorting: .manual
            )
        }

        static func persistentIdentifier(_ derivationIndex: Int) -> AnyHashable {
            CryptoAccountDerivationIdentity(derivationIndex: derivationIndex, type: .crypto).toPersistentIdentifier()
        }
    }
}

// MARK: - Doubles

private final class NetworkServiceSpy: CryptoAccountsNetworkService, WalletsNetworkService {
    private let state = OSAllocatedUnfairLock<[StoredCryptoAccount]>(initialState: [])

    var savedAccounts: [StoredCryptoAccount] { state.withLock { $0 } }

    func getCryptoAccounts(
        retryCount: Int
    ) async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo {
        Self.makeInfo(accounts: savedAccounts)
    }

    func saveAccounts(
        from cryptoAccounts: [StoredCryptoAccount],
        retryCount: Int
    ) async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo {
        state.withLock { $0 = cryptoAccounts }

        return Self.makeInfo(accounts: cryptoAccounts)
    }

    func saveTokens(
        from cryptoAccounts: [StoredCryptoAccount],
        retryCount: Int
    ) async throws(CryptoAccountsNetworkServiceError) {
        throw .underlyingError(StubError.unexpectedCall)
    }

    func createWallet(with context: some Encodable) async throws -> String? {
        throw StubError.unexpectedCall
    }

    func updateWallet(context: some Encodable) async throws {
        throw StubError.unexpectedCall
    }

    private static func makeInfo(accounts: [StoredCryptoAccount]) -> RemoteCryptoAccountsInfo {
        RemoteCryptoAccountsInfo(
            counters: RemoteCryptoAccountsInfo.Counters(archived: 0, crypto: accounts.count, joint: nil),
            accounts: accounts,
            legacyTokens: [],
            legacyGrouping: .none,
            legacySorting: .manual
        )
    }

    enum StubError: Error {
        case unexpectedCall
    }
}

@available(iOS, deprecated: 100000.0, message: "Conforms to a deprecated migration-only protocol")
private final class TokenItemsRepositoryStub: TokenItemsRepository {
    var containsFile: Bool { false }

    func update(_ list: StoredUserTokenList) {}
    func getList() -> StoredUserTokenList { .empty }
}

private final class DefaultAccountFactoryStub: DefaultAccountFactory {
    func makeDefaultAccount(
        defaultTokensOverride: [StoredCryptoAccount.Token]?,
        defaultGroupingOverride: StoredCryptoAccount.Grouping?,
        defaultSortingOverride: StoredCryptoAccount.Sorting?
    ) -> StoredCryptoAccount {
        CryptoAccountsRepositoryReorderTests.Fixtures.account(derivationIndex: 0)
    }

    func makeDefaultAccountPreferringExisting(
        defaultTokensOverride: [StoredCryptoAccount.Token]?,
        defaultGroupingOverride: StoredCryptoAccount.Grouping?,
        defaultSortingOverride: StoredCryptoAccount.Sorting?
    ) -> StoredCryptoAccount {
        CryptoAccountsRepositoryReorderTests.Fixtures.account(derivationIndex: 0)
    }
}

private final class WalletLifecycleObserverStub: WalletLifecycleObserver {
    func walletDidCreate(with userWalletId: UserWalletId) {}
}

private final class AuxiliaryDataStorageStub: CryptoAccountsAuxiliaryDataStorage {
    var didChangePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
    var hasSyncedWithRemote: Bool = true
    var archivedAccountsCount: Int = 0
    var totalCryptoAccountsCount: Int = 1
    var totalJointAccountsCount: Int = 0
}

private final class PersistentStorageStub: CryptoAccountsPersistentStorage {
    private let accounts: OSAllocatedUnfairLock<[StoredCryptoAccount]>

    init(accounts: [StoredCryptoAccount]) {
        self.accounts = OSAllocatedUnfairLock(initialState: accounts)
    }

    func getList() -> [StoredCryptoAccount] {
        accounts.withLock { $0 }
    }

    func appendNewOrUpdateExisting(_ newAccounts: [StoredCryptoAccount]) {
        accounts.withLock { $0.append(contentsOf: newAccounts) }
    }

    func replace(with newAccounts: [StoredCryptoAccount]) {
        accounts.withLock { $0 = newAccounts }
    }

    func removeAll(where shouldBeRemoved: @escaping (StoredCryptoAccount) -> Bool) {
        accounts.withLock { $0.removeAll(where: shouldBeRemoved) }
    }
}

private final class PersistentStorageControllerStub: CryptoAccountsPersistentStorageController {
    func bind(to storageDidUpdateSubject: StorageDidUpdateSubject) {}
    func isMigrationNeeded() -> Bool { false }
}
