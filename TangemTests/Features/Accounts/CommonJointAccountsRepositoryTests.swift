//
//  CommonJointAccountsRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import BigInt
import Testing
import TangemFoundation
@testable import Tangem

// MARK: - Tests

/// What a read from the backend does to what a wallet has stored about its joint accounts.
@Suite("Tests for reading a wallet's joint accounts back from the backend")
struct CommonJointAccountsRepositoryTests {
    @Test("What the endpoint answers for is what gets stored")
    func remoteAccountOverwritesTheStoredOne() async throws {
        let storage = JointAccountsPersistentStorageStub(accounts: [
            Self.storedAccount(status: .pending, memberNames: ["Alice"]),
        ])
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [
            Self.remoteAccount(status: .active(safeAddress: "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"), memberNames: ["Alice", "Bob"]),
        ])
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

        try await sut.loadJointAccountsFromRemote()

        let account = try #require(storage.accounts.first)
        #expect(storage.accounts.count == 1)
        #expect(account.status == .active(safeAddress: "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"))
        #expect(account.members.map(\.name) == ["Alice", "Bob"])
    }

    @Test("Invites are kept apart from the accounts, so a read has nothing to say about them")
    func invitesSurviveARead() async throws {
        let invites = [StoredJointAccountInvite(id: "A1B2C3"), StoredJointAccountInvite(id: "D4E5F6")]
        let storage = JointAccountsPersistentStorageStub(accounts: [Self.storedAccount(status: .pending)])
        let invitesStorage = JointAccountsInvitesPersistentStorageStub(invites: invites, forCryptoAccountId: Self.accountId)
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [
            Self.remoteAccount(status: .confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"), memberNames: ["Alice", "Bob"]),
        ])
        let sut = Self.makeSUT(networkService: networkService, storage: storage, invitesStorage: invitesStorage)

        try await sut.loadJointAccountsFromRemote()

        #expect(invitesStorage.getInvites(forCryptoAccountId: Self.accountId) == invites)
        #expect(storage.accounts.first?.status == .confirming(safeAddress: "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"))
    }

    @Test("An account gone from the answer leaves its invites behind, since nothing can hand them out again")
    func invitesOutliveTheAccountVanishingFromTheAnswer() async throws {
        let invites = [StoredJointAccountInvite(id: "A1B2C3")]
        let storage = JointAccountsPersistentStorageStub(accounts: [Self.storedAccount()])
        let invitesStorage = JointAccountsInvitesPersistentStorageStub(invites: invites, forCryptoAccountId: Self.accountId)
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [])
        let sut = Self.makeSUT(networkService: networkService, storage: storage, invitesStorage: invitesStorage)

        try await sut.loadJointAccountsFromRemote()

        #expect(storage.accounts.isEmpty)
        #expect(invitesStorage.getInvites(forCryptoAccountId: Self.accountId) == invites)
    }

    @Test("The operations riding inside an account are stored apart from it")
    func pendingOperationsAreStoredApartFromTheAccount() async throws {
        let operation = Self.operation()
        let storage = JointAccountsPersistentStorageStub(accounts: [])
        let pendingOperationsStorage = JointAccountsPendingOperationsPersistentStorageStub()
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [
            Self.remoteAccount(status: .active(safeAddress: "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"), operations: [operation]),
            Self.remoteAccount(cryptoAccountId: Self.otherAccountId),
        ])
        let sut = Self.makeSUT(networkService: networkService, storage: storage, pendingOperationsStorage: pendingOperationsStorage)

        try await sut.loadJointAccountsFromRemote()

        #expect(storage.accounts.map(\.cryptoAccountId) == [Self.accountId, Self.otherAccountId])
        #expect(pendingOperationsStorage.records == [StoredJointAccountPendingOperations(cryptoAccountId: Self.accountId, operations: [operation])])
    }

    @Test("An account with nothing in flight any more takes its operations record away")
    func settledOperationsAreDropped() async throws {
        let storage = JointAccountsPersistentStorageStub(accounts: [Self.storedAccount()])
        let pendingOperationsStorage = JointAccountsPendingOperationsPersistentStorageStub(records: [
            StoredJointAccountPendingOperations(cryptoAccountId: Self.accountId, operations: [Self.operation()]),
        ])
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [Self.remoteAccount()])
        let sut = Self.makeSUT(networkService: networkService, storage: storage, pendingOperationsStorage: pendingOperationsStorage)

        try await sut.loadJointAccountsFromRemote()

        #expect(storage.accounts.count == 1)
        #expect(pendingOperationsStorage.records.isEmpty)
    }

    @Test("An account the endpoint no longer reports is no longer stored")
    func anAccountMissingFromTheAnswerIsDropped() async throws {
        let storage = JointAccountsPersistentStorageStub(accounts: [
            Self.storedAccount(cryptoAccountId: Self.accountId),
            Self.storedAccount(cryptoAccountId: Self.otherAccountId),
        ])
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [
            Self.remoteAccount(cryptoAccountId: Self.accountId),
        ])
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

        try await sut.loadJointAccountsFromRemote()

        #expect(storage.accounts.map(\.cryptoAccountId) == [Self.accountId])
    }

    @Test("An answer with no accounts in it is an answer, and it empties the storage")
    func anEmptyAnswerEmptiesTheStorage() async throws {
        let storage = JointAccountsPersistentStorageStub(accounts: [Self.storedAccount()])
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [])
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

        try await sut.loadJointAccountsFromRemote()

        #expect(storage.accounts.isEmpty)
    }

    @Test("Nothing is asked of the endpoint while the feature is off, and what is stored stands")
    func nothingIsAskedWhileTheFeatureIsOff() async throws {
        let storage = JointAccountsPersistentStorageStub(accounts: [Self.storedAccount()])
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [])
        let sut = Self.makeSUT(networkService: networkService, storage: storage, isJointAccountsAvailable: false)

        try await sut.loadJointAccountsFromRemote()

        #expect(networkService.getJointAccountsCallsCount == 0)
        #expect(storage.accounts.count == 1)
    }

    @Test("An account is not created while the feature is off either")
    func nothingIsCreatedWhileTheFeatureIsOff() async throws {
        let storage = JointAccountsPersistentStorageStub(accounts: [])
        let invitesStorage = JointAccountsInvitesPersistentStorageStub()
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [])
        let sut = Self.makeSUT(
            networkService: networkService,
            storage: storage,
            invitesStorage: invitesStorage,
            isJointAccountsAvailable: false
        )

        await #expect(throws: CommonJointAccountsRepository.InternalError.featureUnavailable) {
            try await sut.addNewJointAccount(withConfig: Self.creationConfig())
        }

        #expect(storage.accounts.isEmpty)
        #expect(invitesStorage.records.isEmpty)
    }

    @Test("The reads asked for together amount to the one request that goes out")
    func readsAskedForTogetherAreCoalesced() async throws {
        let storage = JointAccountsPersistentStorageStub(accounts: [])
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [Self.remoteAccount()])
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

        async let first: Void = sut.loadJointAccountsFromRemote()
        async let second: Void = sut.loadJointAccountsFromRemote()

        _ = try await (first, second)

        #expect(networkService.getJointAccountsCallsCount == 1)
        #expect(storage.accounts.count == 1)
    }

    @Test("A list the endpoint reports unchanged leaves the storage exactly as it was")
    func anUnchangedListLeavesTheStorageAlone() async throws {
        let storage = JointAccountsPersistentStorageStub(accounts: [Self.storedAccount()])
        let networkService = JointAccountsNetworkServiceStub(answersUnchanged: true)
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

        try await sut.loadJointAccountsFromRemote()

        #expect(networkService.getJointAccountsCallsCount == 1)
        #expect(storage.accounts.count == 1)
    }

    @Test("A failed read leaves what is stored alone and reports the failure to whoever waited")
    func aFailedReadChangesNothing() async throws {
        let storage = JointAccountsPersistentStorageStub(accounts: [Self.storedAccount()])
        let networkService = JointAccountsNetworkServiceStub(error: TestError.failedToRead)
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

        await #expect(throws: TestError.failedToRead) {
            try await sut.loadJointAccountsFromRemote()
        }

        #expect(storage.accounts.count == 1)
    }

    @Test("A screen asking for frequent updates gets them whatever state the accounts are in")
    func frequentUpdatesAreGrantedToAScreen() {
        let mode = Self.pollingMode(accounts: [Self.storedAccount(status: .active(safeAddress: Self.safeAddress))], frequentUpdatesRequestsCount: 1)

        #expect(mode == .frequent)
    }

    @Test("An account waiting for members or activation is polled regularly", arguments: [JointAccountStatus.pending, .confirming(safeAddress: nil)])
    func pendingAccountsArePolledRegularly(status: JointAccountStatus) {
        let mode = Self.pollingMode(accounts: [Self.storedAccount(status: status)])

        #expect(mode == .regular)
    }

    @Test("An operation in flight is polled regularly")
    func pendingOperationsArePolledRegularly() {
        let mode = Self.pollingMode(
            pendingOperations: [StoredJointAccountPendingOperations(cryptoAccountId: Self.accountId, operations: [Self.operation()])],
            accounts: [Self.storedAccount(status: .active(safeAddress: Self.safeAddress))]
        )

        #expect(mode == .regular)
    }

    @Test("Nothing is polled once every account has settled and no operation is in flight")
    func settledAccountsAreNotPolled() {
        let mode = Self.pollingMode(accounts: [Self.storedAccount(status: .active(safeAddress: Self.safeAddress))])

        #expect(mode == .idle)
    }
}

// MARK: - Helpers

private extension CommonJointAccountsRepositoryTests {
    static let accountId = "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A"
    static let otherAccountId = "1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C"

    static func makeSUT(
        networkService: JointAccountsNetworkService,
        storage: JointAccountsPersistentStorage,
        invitesStorage: JointAccountsInvitesPersistentStorage = JointAccountsInvitesPersistentStorageStub(),
        pendingOperationsStorage: JointAccountsPendingOperationsPersistentStorage = JointAccountsPendingOperationsPersistentStorageStub(),
        isJointAccountsAvailable: Bool = true
    ) -> CommonJointAccountsRepository {
        CommonJointAccountsRepository(
            userWalletId: UserWalletId(value: .randomData(count: 32)),
            networkService: networkService,
            derivationInteractorFactory: JointAccountDerivationInteractorFactory(),
            persistentStorage: storage,
            invitesPersistentStorage: invitesStorage,
            pendingOperationsPersistentStorage: pendingOperationsStorage,
            isJointAccountsAvailable: isJointAccountsAvailable
        )
    }

    static func creationConfig() -> JointAccountCreationConfig {
        JointAccountCreationConfig(
            creationContext: JointAccountCreationContext(
                name: "Vacation fund",
                icon: AccountModel.CompositeIcon(name: .beach, color: .azure),
                membersCount: 3,
                signersCount: 2,
                creatorName: "Alice"
            ),
            derivationIndex: 0
        )
    }

    static let safeAddress = "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21b"

    static func pollingMode(
        pendingOperations: [StoredJointAccountPendingOperations] = [],
        accounts: [StoredJointAccount],
        frequentUpdatesRequestsCount: Int = 0
    ) -> CommonJointAccountsRepository.JointAccountsRepositoryAutoupdater.PollingMode {
        CommonJointAccountsRepository.JointAccountsRepositoryAutoupdater.pollingMode(
            pendingOperations: pendingOperations,
            accounts: accounts,
            frequentUpdatesRequestsCount: frequentUpdatesRequestsCount
        )
    }

    static func storedAccount(
        cryptoAccountId: String = accountId,
        status: JointAccountStatus = .pending,
        memberNames: [String] = ["Alice"]
    ) -> StoredJointAccount {
        StoredJointAccount(
            cryptoAccountId: cryptoAccountId,
            membersCount: 3,
            threshold: 2,
            status: status,
            members: members(named: memberNames)
        )
    }

    static func remoteAccount(
        cryptoAccountId: String = accountId,
        status: JointAccountStatus = .pending,
        memberNames: [String] = ["Alice"],
        operations: [JointAccountOperation] = []
    ) -> RemoteJointAccount {
        RemoteJointAccount(
            cryptoAccountId: cryptoAccountId,
            membersCount: 3,
            threshold: 2,
            status: status,
            members: members(named: memberNames),
            operations: operations
        )
    }

    static func operation(chainId: Int = 1) -> JointAccountOperation {
        JointAccountOperation(
            id: "0E2F4A6C-8D0B-4C5E-9F1A-2D4B6C8E0F2A",
            chainId: chainId,
            safeTransaction: SafeTransaction(
                to: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c",
                value: BigUInt(10).power(18),
                data: Data(),
                operation: 0,
                safeTxGas: 23_520,
                baseGas: 100_000,
                gasPrice: 1_575_000_000,
                gasToken: "0x0000000000000000000000000000000000000000",
                refundReceiver: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
                nonce: 7
            ),
            status: .awaitingSignatures,
            initiator: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
            signatures: [JointAccountOperation.Signature(address: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf", state: .signed, at: "2026-09-02T10:15:00Z")]
        )
    }

    static func members(named names: [String]) -> [StoredJointAccount.Member] {
        names.enumerated().map { index, name in
            StoredJointAccount.Member(
                name: name,
                address: "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21\(index)",
                role: index == 0 ? .creator : .member,
                inviteId: nil
            )
        }
    }

    enum TestError: Error, Equatable {
        case failedToRead
    }
}

// MARK: - Test doubles

private final class JointAccountsNetworkServiceStub: JointAccountsNetworkService {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var getJointAccountsCallsCount: Int {
        state.withLock(\.getJointAccountsCallsCount)
    }

    init(jointAccounts: [RemoteJointAccount] = [], answersUnchanged: Bool = false, error: Error? = nil) {
        state.withLock {
            $0.jointAccounts = jointAccounts
            $0.answersUnchanged = answersUnchanged
            $0.error = error
        }
    }

    func getJointAccounts() async throws -> JointAccountsRemoteState {
        try state.withLock { state in
            state.getJointAccountsCallsCount += 1

            if let error = state.error {
                throw error
            }

            return state.answersUnchanged ? .notModified : .changed(state.jointAccounts)
        }
    }

    func createJointAccount(blob: JointAccountCreationBlob) async throws -> JointAccountCreationResult {
        throw "Not called by these tests"
    }

    func getInvitePreview(inviteId: String) async throws -> JointAccountInvitePreview {
        throw "Not called by these tests"
    }

    func joinJointAccount(blob: JointAccountJoinBlob) async throws -> RemoteJointAccount {
        throw "Not called by these tests"
    }

    func activateJointAccount(blob: JointAccountActivationBlob) async throws -> RemoteJointAccount {
        throw "Not called by these tests"
    }

    func createOperation(_ request: JointAccountOperationRequest) async throws -> JointAccountOperation {
        throw "Not called by these tests"
    }

    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data) async throws -> JointAccountOperation {
        throw "Not called by these tests"
    }

    func rejectOperation(id: String) async throws -> JointAccountOperation? {
        throw "Not called by these tests"
    }
}

private extension JointAccountsNetworkServiceStub {
    struct State {
        var jointAccounts: [RemoteJointAccount] = []
        var answersUnchanged = false
        var error: Error?
        var getJointAccountsCallsCount = 0
    }
}

private final class JointAccountsInvitesPersistentStorageStub: JointAccountsInvitesPersistentStorage {
    private let recordsLock: OSAllocatedUnfairLock<[StoredJointAccountInvites]>
    private let didUpdateSubject = PassthroughSubject<Void, Never>()

    var records: [StoredJointAccountInvites] {
        recordsLock.withLock { $0 }
    }

    var didUpdatePublisher: AnyPublisher<Void, Never> {
        didUpdateSubject.eraseToAnyPublisher()
    }

    init(records: [StoredJointAccountInvites] = []) {
        recordsLock = OSAllocatedUnfairLock(initialState: records)
    }

    func getList() -> [StoredJointAccountInvites] {
        records
    }

    convenience init(invites: [StoredJointAccountInvite], forCryptoAccountId cryptoAccountId: String) {
        self.init(records: [StoredJointAccountInvites(cryptoAccountId: cryptoAccountId, invites: invites)])
    }

    func getInvites(forCryptoAccountId cryptoAccountId: String) -> [StoredJointAccountInvite]? {
        recordsLock.withLock { records in
            records.first { $0.cryptoAccountId.caseInsensitiveEquals(to: cryptoAccountId) }?.invites
        }
    }

    func save(_ invites: [StoredJointAccountInvite], forCryptoAccountId cryptoAccountId: String) throws {
        recordsLock.withLock { records in
            let record = StoredJointAccountInvites(cryptoAccountId: cryptoAccountId, invites: invites)

            if let index = records.firstIndex(where: { $0.cryptoAccountId.caseInsensitiveEquals(to: cryptoAccountId) }) {
                records[index] = record
            } else {
                records.append(record)
            }
        }

        didUpdateSubject.send()
    }
}

private final class JointAccountsPersistentStorageStub: JointAccountsPersistentStorage {
    private let accountsLock: OSAllocatedUnfairLock<[StoredJointAccount]>
    private let didUpdateSubject = PassthroughSubject<Void, Never>()

    var accounts: [StoredJointAccount] {
        accountsLock.withLock { $0 }
    }

    var didUpdatePublisher: AnyPublisher<Void, Never> {
        didUpdateSubject.eraseToAnyPublisher()
    }

    init(accounts: [StoredJointAccount]) {
        accountsLock = OSAllocatedUnfairLock(initialState: accounts)
    }

    func getList() -> [StoredJointAccount] {
        accounts
    }

    func appendNewOrUpdateExisting(_ account: StoredJointAccount) throws {
        accountsLock.withLock { accounts in
            if let index = accounts.firstIndex(where: { $0.cryptoAccountId.caseInsensitiveEquals(to: account.cryptoAccountId) }) {
                accounts[index] = account
            } else {
                accounts.append(account)
            }
        }

        didUpdateSubject.send()
    }

    func replace(with accounts: [StoredJointAccount]) throws {
        accountsLock.withLock { $0 = accounts }
        didUpdateSubject.send()
    }
}

private final class JointAccountsPendingOperationsPersistentStorageStub: JointAccountsPendingOperationsPersistentStorage {
    private let recordsLock: OSAllocatedUnfairLock<[StoredJointAccountPendingOperations]>
    private let didUpdateSubject = PassthroughSubject<Void, Never>()

    var records: [StoredJointAccountPendingOperations] {
        recordsLock.withLock { $0 }
    }

    var didUpdatePublisher: AnyPublisher<Void, Never> {
        didUpdateSubject.eraseToAnyPublisher()
    }

    init(records: [StoredJointAccountPendingOperations] = []) {
        recordsLock = OSAllocatedUnfairLock(initialState: records)
    }

    func getList() -> [StoredJointAccountPendingOperations] {
        records
    }

    func replace(with records: [StoredJointAccountPendingOperations]) throws {
        recordsLock.withLock { $0 = records }
        didUpdateSubject.send()
    }

    func appendNewOrUpdateExisting(_ operation: JointAccountOperation, forCryptoAccountId cryptoAccountId: String) throws {
        throw "Not called by these tests"
    }

    func remove(operationWithId operationId: String, forCryptoAccountId cryptoAccountId: String) throws {
        throw "Not called by these tests"
    }
}
