//
//  CommonJointAccountsRepositoryTests.swift
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
            Self.remoteAccount(status: .active, memberNames: ["Alice", "Bob"]),
        ])
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

        try await sut.loadJointAccountsFromRemote()

        let account = try #require(storage.accounts.first)
        #expect(storage.accounts.count == 1)
        #expect(account.status == .active)
        #expect(account.members.map(\.name) == ["Alice", "Bob"])
    }

    @Test("Invites are kept apart from the accounts, so a read has nothing to say about them")
    func invitesSurviveARead() async throws {
        let invites = [JointAccountInvite(id: "A1B2C3"), JointAccountInvite(id: "D4E5F6")]
        let storage = JointAccountsPersistentStorageStub(accounts: [Self.storedAccount(status: .pending)])
        let invitesStorage = JointAccountsInvitesPersistentStorageStub(invites: invites, forCryptoAccountId: Self.accountId)
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [
            Self.remoteAccount(status: .confirming, memberNames: ["Alice", "Bob"]),
        ])
        let sut = Self.makeSUT(networkService: networkService, storage: storage, invitesStorage: invitesStorage)

        try await sut.loadJointAccountsFromRemote()

        #expect(invitesStorage.getInvites(forCryptoAccountId: Self.accountId) == invites)
        #expect(storage.accounts.first?.status == .confirming)
    }

    @Test("An account gone from the answer leaves its invites behind, since nothing can hand them out again")
    func invitesOutliveTheAccountVanishingFromTheAnswer() async throws {
        let invites = [JointAccountInvite(id: "A1B2C3")]
        let storage = JointAccountsPersistentStorageStub(accounts: [Self.storedAccount()])
        let invitesStorage = JointAccountsInvitesPersistentStorageStub(invites: invites, forCryptoAccountId: Self.accountId)
        let networkService = JointAccountsNetworkServiceStub(jointAccounts: [])
        let sut = Self.makeSUT(networkService: networkService, storage: storage, invitesStorage: invitesStorage)

        try await sut.loadJointAccountsFromRemote()

        #expect(storage.accounts.isEmpty)
        #expect(invitesStorage.getInvites(forCryptoAccountId: Self.accountId) == invites)
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
}

// MARK: - Helpers

private extension CommonJointAccountsRepositoryTests {
    static let accountId = "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A"
    static let otherAccountId = "1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C"

    static func makeSUT(
        networkService: JointAccountsNetworkService,
        storage: JointAccountsPersistentStorage,
        invitesStorage: JointAccountsInvitesPersistentStorage = JointAccountsInvitesPersistentStorageStub(),
        isJointAccountsAvailable: Bool = true
    ) -> CommonJointAccountsRepository {
        CommonJointAccountsRepository(
            userWalletId: UserWalletId(value: .randomData(count: 32)),
            networkService: networkService,
            derivationInteractorFactory: JointAccountDerivationInteractorFactory(),
            persistentStorage: storage,
            invitesPersistentStorage: invitesStorage,
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

    static func storedAccount(
        cryptoAccountId: String = accountId,
        status: JointAccountStatus = .pending,
        memberNames: [String] = ["Alice"]
    ) -> StoredJointAccount {
        StoredJointAccount(
            cryptoAccountId: cryptoAccountId,
            membersCount: 3,
            threshold: 2,
            address: nil,
            status: status,
            members: members(named: memberNames)
        )
    }

    static func remoteAccount(
        cryptoAccountId: String = accountId,
        status: JointAccountStatus = .pending,
        memberNames: [String] = ["Alice"]
    ) -> RemoteJointAccount {
        RemoteJointAccount(
            cryptoAccountId: cryptoAccountId,
            membersCount: 3,
            threshold: 2,
            address: nil,
            status: status,
            members: members(named: memberNames)
        )
    }

    static func members(named names: [String]) -> [StoredJointAccount.Member] {
        names.enumerated().map { index, name in
            StoredJointAccount.Member(
                name: name,
                address: "0x8f3a1C5E7B9D0246A8C0E2B4D6F8A0C2E4B6c21\(index)",
                role: index == 0 ? .creator : .member
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

    init(jointAccounts: [RemoteJointAccount] = [], error: Error? = nil) {
        state.withLock {
            $0.jointAccounts = jointAccounts
            $0.error = error
        }
    }

    func getJointAccounts() async throws -> [RemoteJointAccount] {
        try state.withLock { state in
            state.getJointAccountsCallsCount += 1

            if let error = state.error {
                throw error
            }

            return state.jointAccounts
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
}

private extension JointAccountsNetworkServiceStub {
    struct State {
        var jointAccounts: [RemoteJointAccount] = []
        var error: Error?
        var getJointAccountsCallsCount = 0
    }
}

private final class JointAccountsInvitesPersistentStorageStub: JointAccountsInvitesPersistentStorage {
    private let recordsLock: OSAllocatedUnfairLock<[StoredJointAccountInvites]>

    var records: [StoredJointAccountInvites] {
        recordsLock.withLock { $0 }
    }

    init(records: [StoredJointAccountInvites] = []) {
        recordsLock = OSAllocatedUnfairLock(initialState: records)
    }

    convenience init(invites: [JointAccountInvite], forCryptoAccountId cryptoAccountId: String) {
        self.init(records: [StoredJointAccountInvites(cryptoAccountId: cryptoAccountId, invites: invites)])
    }

    func getInvites(forCryptoAccountId cryptoAccountId: String) -> [JointAccountInvite]? {
        recordsLock.withLock { records in
            records.first { $0.cryptoAccountId.caseInsensitiveEquals(to: cryptoAccountId) }?.invites
        }
    }

    func save(_ invites: [JointAccountInvite], forCryptoAccountId cryptoAccountId: String) throws {
        recordsLock.withLock { records in
            let record = StoredJointAccountInvites(cryptoAccountId: cryptoAccountId, invites: invites)

            if let index = records.firstIndex(where: { $0.cryptoAccountId.caseInsensitiveEquals(to: cryptoAccountId) }) {
                records[index] = record
            } else {
                records.append(record)
            }
        }
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
