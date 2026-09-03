//
//  CryptoAccountsRepositoryLoadTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemAccounts
import TangemFoundation
@testable import Tangem

/// Locks down the single-flight invariant of loading accounts from the server: a request arriving while a load is
/// already in flight has to join it instead of starting a second one. Starting a second load overwrites the
/// single-slot subscription of the first, cancels it and abandons every completion it carries — which used to leave
/// `CommonUserTokensManager` with a queue that never drains and pull-to-refresh disabled until an app restart.
@Suite("Crypto accounts repository — loading accounts from server")
struct CryptoAccountsRepositoryLoadTests {
    @Test("A request arriving during a load joins it: a single network call, every completion delivered")
    func requestArrivingDuringLoadJoinsIt() async {
        let networkService = NetworkServiceStub()
        let adapter = Self.makeAdapter(networkService: networkService)
        let results = ResultsCollector()

        // The first request reaches the network and stays there until the test releases it.
        adapter.updateLocalRepositoryFromServer { results.append($0) }
        let didReachNetwork = await Poll.until(timeout: Constants.timeout) { networkService.requestCount >= 1 }
        #expect(didReachNetwork, "the first request never reached the network")

        // The second request lands while the first load is still in flight. The wait exceeds the debounce interval,
        // so it forms its own batch instead of being coalesced into the first one.
        adapter.updateLocalRepositoryFromServer { results.append($0) }
        try? await Task.sleep(for: .seconds(Constants.debounceSettling))

        networkService.releaseRequests()

        let didDeliverBoth = await Poll.until(timeout: Constants.timeout) { results.count >= 2 }

        #expect(networkService.requestCount == 1, "a second load must not be started while one is already in flight")
        #expect(didDeliverBoth, "every queued completion must be delivered, got \(results.count) of 2")
    }
}

// MARK: - Factory

private extension CryptoAccountsRepositoryLoadTests {
    static func makeAdapter(networkService: NetworkServiceStub) -> UserTokensRepositoryAdapter {
        let repository = CommonCryptoAccountsRepository(
            tokenItemsRepository: TokenItemsRepositoryStub(),
            defaultAccountFactory: DefaultAccountFactoryStub(),
            networkService: networkService,
            walletLifecycleObserver: WalletLifecycleObserverStub(),
            auxiliaryDataStorage: AuxiliaryDataStorageStub(),
            persistentStorage: PersistentStorageStub(),
            storageController: PersistentStorageControllerStub(),
            hasTokenSynchronization: true
        )

        return UserTokensRepositoryAdapter(innerRepository: repository, derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 0, type: .crypto))
    }

    enum Constants {
        /// Must exceed `CommonCryptoAccountsRepository`'s debounce interval so the second request forms its own batch.
        static let debounceSettling: TimeInterval = 1
        static let timeout: TimeInterval = 5
    }
}

// MARK: - Polling

private enum Poll {
    static func until(timeout: TimeInterval, _ condition: () -> Bool) async -> Bool {
        let step: TimeInterval = 0.02
        var waited: TimeInterval = 0

        while waited < timeout {
            if condition() {
                return true
            }

            try? await Task.sleep(for: .seconds(step))
            waited += step
        }

        return condition()
    }
}

// MARK: - Results collector

private final class ResultsCollector {
    private let results = OSAllocatedUnfairLock(initialState: [Bool]())

    var count: Int { results.withLock(\.count) }

    func append(_ result: UserTokensRepository.Result) {
        results.withLock { $0.append(result.error == nil) }
    }
}

// MARK: - Stubs

private final class NetworkServiceStub: CryptoAccountsNetworkService, WalletsNetworkService {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var requestCount: Int { state.withLock(\.requestCount) }

    func releaseRequests() {
        state.withLock { $0.isReleased = true }
    }

    func getCryptoAccounts(retryCount: Int) async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo {
        state.withLock { $0.requestCount += 1 }
        await waitForRelease()

        throw .underlyingError(StubError.releasedByTest)
    }

    func saveAccounts(
        from cryptoAccounts: [StoredCryptoAccount],
        retryCount: Int
    ) async throws(CryptoAccountsNetworkServiceError) -> RemoteCryptoAccountsInfo {
        throw .underlyingError(StubError.unexpectedCall)
    }

    func saveTokens(from cryptoAccounts: [StoredCryptoAccount], retryCount: Int) async throws(CryptoAccountsNetworkServiceError) {
        throw .underlyingError(StubError.unexpectedCall)
    }

    func createWallet(with context: some Encodable) async throws -> String? {
        throw StubError.unexpectedCall
    }

    func updateWallet(context: some Encodable) async throws {
        throw StubError.unexpectedCall
    }

    /// Deliberately not cancellation-aware apart from bailing out: the request has to stay in flight until the test
    /// releases it, so that the second request is guaranteed to arrive while the first load is still running.
    private func waitForRelease() async {
        while !state.withLock(\.isReleased), !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    private struct State {
        var requestCount = 0
        var isReleased = false
    }

    enum StubError: Error {
        case releasedByTest
        case unexpectedCall
    }
}

@available(iOS, deprecated: 100000.0, message: "Conforms to a deprecated migration-only protocol")
private final class TokenItemsRepositoryStub: TokenItemsRepository {
    var containsFile: Bool { false }

    func update(_ list: StoredUserTokenList) {}
    func append(_ entries: [StoredUserTokenList.Entry]) {}
    func remove(_ blockchainNetworks: [BlockchainNetwork], completion: (() -> Void)?) { completion?() }
    func remove(_ entries: [StoredUserTokenList.Entry]) {}
    func removeAll() {}
    func getList() -> StoredUserTokenList { .empty }
}

private final class DefaultAccountFactoryStub: DefaultAccountFactory {
    func makeDefaultAccount(
        defaultTokensOverride: [StoredCryptoAccount.Token]?,
        defaultGroupingOverride: StoredCryptoAccount.Grouping?,
        defaultSortingOverride: StoredCryptoAccount.Sorting?
    ) -> StoredCryptoAccount {
        Self.makeAccount()
    }

    func makeDefaultAccountPreferringExisting(
        defaultTokensOverride: [StoredCryptoAccount.Token]?,
        defaultGroupingOverride: StoredCryptoAccount.Grouping?,
        defaultSortingOverride: StoredCryptoAccount.Sorting?
    ) -> StoredCryptoAccount {
        Self.makeAccount()
    }

    private static func makeAccount() -> StoredCryptoAccount {
        let icon = AccountModel.CompositeIcon(name: .allCases[0], color: .allCases[0])
        let config = CryptoAccountPersistentConfig(derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 0, type: .crypto), name: nil, icon: icon)

        return StoredCryptoAccount(config: config, tokenListAppearance: .default)
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
    private let accounts = OSAllocatedUnfairLock(initialState: [StoredCryptoAccount]())

    func getList() -> [StoredCryptoAccount] { accounts.withLock { $0 } }
    func appendNewOrUpdateExisting(_ newAccounts: [StoredCryptoAccount]) { accounts.withLock { $0.append(contentsOf: newAccounts) } }
    func replace(with newAccounts: [StoredCryptoAccount]) { accounts.withLock { $0 = newAccounts } }
    func removeAll(where shouldBeRemoved: @escaping (StoredCryptoAccount) -> Bool) { accounts.withLock { $0.removeAll(where: shouldBeRemoved) } }
}

private final class PersistentStorageControllerStub: CryptoAccountsPersistentStorageController {
    func bind(to storageDidUpdateSubject: StorageDidUpdateSubject) {}
    func isMigrationNeeded() -> Bool { false }
}
