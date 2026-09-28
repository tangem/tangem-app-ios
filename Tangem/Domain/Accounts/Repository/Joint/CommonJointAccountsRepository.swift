//
//  CommonJointAccountsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import Combine
import os
import BlockchainSdk
import CombineExt
import TangemFoundation

final class CommonJointAccountsRepository {
    private typealias LoadResult = Result<Void, Error>

    private let userWalletId: UserWalletId
    private let networkService: JointAccountsNetworkService
    private let derivationInteractorFactory: JointAccountDerivationInteractorFactory
    private let persistentStorage: JointAccountsPersistentStorage
    private let invitesPersistentStorage: JointAccountsInvitesPersistentStorage
    private let pendingOperationsPersistentStorage: JointAccountsPendingOperationsPersistentStorage
    private let isJointAccountsAvailable: Bool

    private lazy var autoupdater = JointAccountsRepositoryAutoupdater(innerRepository: self, isJointAccountsAvailable: isJointAccountsAvailable)
    private var loadAccountsSubscription: AnyCancellable?

    /// - Note: The list is asked for often, and every asker gets the answer of the one request that actually goes out.
    private lazy var loadJointAccountsDebouncer = Debouncer<LoadResult>(interval: Constants.debounceInterval) { [weak self] completion in
        guard let self else {
            // The callers wait through continuations, so even a dead repository has to answer rather than hang them
            completion(.failure(CancellationError()))
            return
        }

        loadJointAccountsFromServer(completion)
    }

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var storageDidUpdatePublisher: AnyPublisher<[StoredJointAccount], Never> = persistentStorage
        .didUpdatePublisher
        .prepend(()) // An initial value to trigger loading from storage
        .receive(on: DispatchQueue.global(qos: .userInitiated))
        .withWeakCaptureOf(self)
        .map { repository, _ in repository.persistentStorage.getList() }
        .removeDuplicates()
        .receiveOnMain()
        .share(replay: 1)
        .eraseToAnyPublisher()

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var invitesStorageDidUpdatePublisher: AnyPublisher<[StoredJointAccountInvites], Never> = invitesPersistentStorage
        .didUpdatePublisher
        .prepend(()) // An initial value to trigger loading from storage
        .receive(on: DispatchQueue.global(qos: .userInitiated))
        .withWeakCaptureOf(self)
        .map { repository, _ in repository.invitesPersistentStorage.getList() }
        .removeDuplicates()
        .receiveOnMain()
        .share(replay: 1)
        .eraseToAnyPublisher()

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var pendingOperationsStorageDidUpdatePublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> = pendingOperationsPersistentStorage
        .didUpdatePublisher
        .prepend(()) // An initial value to trigger loading from storage
        .receive(on: DispatchQueue.global(qos: .userInitiated))
        .withWeakCaptureOf(self)
        .map { repository, _ in repository.pendingOperationsPersistentStorage.getList() }
        .removeDuplicates()
        .receiveOnMain()
        .share(replay: 1)
        .eraseToAnyPublisher()

    init(
        userWalletId: UserWalletId,
        networkService: JointAccountsNetworkService,
        derivationInteractorFactory: JointAccountDerivationInteractorFactory,
        persistentStorage: JointAccountsPersistentStorage,
        invitesPersistentStorage: JointAccountsInvitesPersistentStorage,
        pendingOperationsPersistentStorage: JointAccountsPendingOperationsPersistentStorage,
        isJointAccountsAvailable: Bool
    ) {
        self.userWalletId = userWalletId
        self.networkService = networkService
        self.derivationInteractorFactory = derivationInteractorFactory
        self.persistentStorage = persistentStorage
        self.invitesPersistentStorage = invitesPersistentStorage
        self.pendingOperationsPersistentStorage = pendingOperationsPersistentStorage
        self.isJointAccountsAvailable = isJointAccountsAvailable

        // Eager initialization of these lazy properties to ensure that there are no race conditions
        _ = loadJointAccountsDebouncer
        _ = storageDidUpdatePublisher
        _ = invitesStorageDidUpdatePublisher
        _ = pendingOperationsStorageDidUpdatePublisher

        _ = autoupdater
    }
}

// MARK: - JointAccountsRepository protocol conformance

extension CommonJointAccountsRepository: JointAccountsRepository {
    var jointAccounts: [StoredJointAccount] {
        persistentStorage.getList()
    }

    var jointAccountsPublisher: AnyPublisher<[StoredJointAccount], Never> {
        storageDidUpdatePublisher
    }

    var jointAccountsInvites: [StoredJointAccountInvites] {
        invitesPersistentStorage.getList()
    }

    var jointAccountsInvitesPublisher: AnyPublisher<[StoredJointAccountInvites], Never> {
        invitesStorageDidUpdatePublisher
    }

    var jointAccountsPendingOperationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> {
        pendingOperationsStorageDidUpdatePublisher
    }

    func initialize() {
        guard isJointAccountsAvailable else {
            return
        }

        loadJointAccountsDebouncer.debounce(withCompletion: { result in
            guard case .failure(let error) = result else {
                return
            }

            JointAccountsLogger.error("Failed to load the joint accounts of a wallet on initialization", error: error)
        })
    }

    func loadJointAccountsFromRemote() async throws {
        try await withCheckedThrowingContinuation { continuation in
            loadJointAccountsDebouncer.debounce(withCompletion: { result in
                continuation.resume(with: result)
            })
        }
    }

    func requestFrequentUpdates() -> AnyCancellable {
        autoupdater.requestFrequentUpdates()
    }

    func addNewJointAccount(withConfig config: JointAccountCreationConfig) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let payloadBuilder = JointAccountCreationPayloadBuilder(
            userWalletId: userWalletId,
            creationContext: config.creationContext
        )
        let interactor = derivationInteractorFactory.makeInteractor()

        let result = try await interactor.deriveAndSign(
            derivationIndex: config.derivationIndex,
            payloadBuilder: payloadBuilder
        )

        let blob = JointAccountCreationBlob(payload: result.payload, signature: result.signature)

        let creationResult = try await networkService.createJointAccount(blob: blob)

        // The invites go first: they are handed out once and never read back, whereas the account itself is reported
        // by every list read, so a failure here costs a record that comes back on its own rather than one that cannot
        try invitesPersistentStorage.save(creationResult.invites, forCryptoAccountId: creationResult.account.cryptoAccountId)
        try persistentStorage.appendNewOrUpdateExisting(StoredJointAccount(remote: creationResult.account))
    }

    func joinJointAccount(withConfig config: JointAccountJoinConfig) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let payloadBuilder = JointAccountJoinPayloadBuilder(
            userWalletId: userWalletId,
            inviteId: config.inviteId,
            config: config.signedConfig,
            memberName: config.memberName
        )
        let interactor = derivationInteractorFactory.makeInteractor()

        let result = try await interactor.deriveAndSign(
            derivationIndex: config.derivationIndex,
            payloadBuilder: payloadBuilder
        )

        let blob = JointAccountJoinBlob(payload: result.payload, signature: result.signature)

        let account = try await networkService.joinJointAccount(blob: blob)

        // No invites come back here: they belong to the creator, and this wallet has just spent the one it was given
        try persistentStorage.appendNewOrUpdateExisting(StoredJointAccount(remote: account))
    }

    func activateJointAccount(withConfig config: JointAccountActivationConfig) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let payloadBuilder = JointAccountActivationPayloadBuilder(
            userWalletId: userWalletId,
            cryptoAccountId: config.cryptoAccountId,
            config: config.signedConfig,
            safeAddress: config.safeAddress
        )
        let interactor = derivationInteractorFactory.makeInteractor()

        let result = try await interactor.deriveAndSign(
            derivationIndex: config.derivationIndex,
            payloadBuilder: payloadBuilder
        )

        // Which wallet was tapped is only known once it has been: a wallet other than the creator's would be turned
        // away by the endpoint anyway, and stopping here says why instead of reporting a bare refusal
        guard result.derivedKey.address.caseInsensitiveCompare(config.creatorAddress) == .orderedSame else {
            throw InternalError.notCreatorWallet
        }

        let blob = JointAccountActivationBlob(payload: result.payload, signature: result.signature)

        let account = try await networkService.activateJointAccount(blob: blob)

        try persistentStorage.appendNewOrUpdateExisting(StoredJointAccount(remote: account))
    }

    func createOperation(_ request: JointAccountOperationRequest, forCryptoAccountId cryptoAccountId: String) async throws -> JointAccountOperation {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let operation = try await networkService.createOperation(request)
        try pendingOperationsPersistentStorage.appendNewOrUpdateExisting(operation, forCryptoAccountId: cryptoAccountId)

        return operation
    }

    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data, forCryptoAccountId cryptoAccountId: String) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let operation = try await networkService.signOperation(id: id, safeTransaction: safeTransaction, signature: signature)
        try pendingOperationsPersistentStorage.appendNewOrUpdateExisting(operation, forCryptoAccountId: cryptoAccountId)
    }

    func rejectOperation(id: String, forCryptoAccountId cryptoAccountId: String) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        guard let operation = try await networkService.rejectOperation(id: id) else {
            try pendingOperationsPersistentStorage.remove(operationWithId: id, forCryptoAccountId: cryptoAccountId)
            return
        }

        try pendingOperationsPersistentStorage.appendNewOrUpdateExisting(operation, forCryptoAccountId: cryptoAccountId)
    }
}

// MARK: - Private

private extension CommonJointAccountsRepository {
    private func loadJointAccountsFromServer(_ completion: @escaping Debouncer<LoadResult>.Completion) {
        // Nothing is asked of the joint accounts endpoints while the feature is off
        guard isJointAccountsAvailable else {
            JointAccountsLogger.debug("Not reading the joint accounts of a wallet while the feature is off")
            completion(.success(()))
            return
        }

        // Weakly captured by hand rather than through `runTask(in:)`, which drops the whole body once the object is
        // gone: the callers wait through continuations, and one left unresumed is a caller hung forever
        loadAccountsSubscription = runTask { [weak self] in
            guard let self else {
                await runOnMain { completion(.failure(CancellationError())) }
                return
            }

            do {
                try await loadJointAccountsFromServerAsync()
                await runOnMain { completion(.success(())) }
            } catch {
                JointAccountsLogger.error("Failed to read the joint accounts of a wallet", error: error)

                // A cancelled load answers too, for the same reason
                await runOnMain { completion(.failure(error)) }
            }
        }.eraseToAnyCancellable()
    }

    func loadJointAccountsFromServerAsync() async throws {
        let remoteState = try await networkService.getJointAccounts()
        try Task.checkCancellation()

        guard case .changed(let remoteJointAccounts) = remoteState else {
            // Nothing is written: the storage already holds this very list, and rewriting it would only wake
            // every subscriber for nothing
            JointAccountsLogger.debug("The joint accounts have not changed since they were last read")
            return
        }

        JointAccountsLogger.info("Loaded \(remoteJointAccounts.count) joint accounts from API.")
        JointAccountsLogger.debug("Accounts: \(remoteJointAccounts)")

        // The invites are not the endpoint's to report, so a read leaves them where they are and says nothing of them
        let accounts = remoteJointAccounts.map(StoredJointAccount.init(remote:))
        let pendingOperations = remoteJointAccounts.compactMap(StoredJointAccountPendingOperations.init(remote:))

        // The operations go first, so that an account arriving in the list finds what is in flight for it already there
        try pendingOperationsPersistentStorage.replace(with: pendingOperations)
        try persistentStorage.replace(with: accounts)
    }
}

// MARK: - Auxiliary types

extension CommonJointAccountsRepository {
    enum InternalError: Error {
        /// Creating an account is asked for by a screen the feature toggle is supposed to keep out of reach, so this
        /// is a programming error rather than something a user can arrive at.
        case featureUnavailable
        /// The wallet that was tapped holds a slot of the account, but not the creator's, and only the creator
        /// activates.
        case notCreatorWallet
    }
}

// MARK: - Constants

private extension CommonJointAccountsRepository {
    enum Constants {
        static let debounceInterval = 0.3
        /// The listing is the only place an operation's progress shows up, so it is re-read this often while one is in flight.
        static let regularPollingInterval: Duration = .seconds(60)
        static let frequentPollingInterval: Duration = .seconds(2)
    }
}

extension CommonJointAccountsRepository {
    final class JointAccountsRepositoryAutoupdater {
        private weak var innerRepository: CommonJointAccountsRepository?
        private let regularPollingProcessor = RepeatedTaskProcessor(duration: Constants.regularPollingInterval)
        private let frequentPollingProcessor = RepeatedTaskProcessor(duration: Constants.frequentPollingInterval)
        private let frequentUpdatesRequestsCount = OSAllocatedUnfairLock(initialState: 0)
        private let frequentUpdatesRequestsCountSubject = CurrentValueSubject<Int, Never>(0)

        private var pollingModeSubscription: Task<Void, Never>?
        private var foregroundSubscription: AnyCancellable?

        init(innerRepository: CommonJointAccountsRepository, isJointAccountsAvailable: Bool) {
            self.innerRepository = innerRepository

            if isJointAccountsAvailable {
                bind(innerRepository: innerRepository)
            }
        }

        deinit {
            pollingModeSubscription?.cancel()
        }

        func requestFrequentUpdates() -> AnyCancellable {
            changeFrequentUpdatesRequestsCount(by: 1)

            return AnyCancellable { [weak self] in
                self?.changeFrequentUpdatesRequestsCount(by: -1)
            }
        }

        static func pollingMode(
            pendingOperations: [StoredJointAccountPendingOperations],
            accounts: [StoredJointAccount],
            frequentUpdatesRequestsCount: Int
        ) -> PollingMode {
            if frequentUpdatesRequestsCount > 0 {
                return .frequent
            }

            let hasPendingAccounts = accounts.contains { account in
                switch account.status {
                case .pending, .confirming: true
                case .active, .cancelled, .unknown: false
                }
            }

            return hasPendingAccounts || !pendingOperations.isEmpty ? .regular : .idle
        }

        private func changeFrequentUpdatesRequestsCount(by delta: Int) {
            frequentUpdatesRequestsCount.withLockUnchecked { count in
                count += delta
                frequentUpdatesRequestsCountSubject.send(count)
            }
        }

        /// One task reads the publisher in order, so a stop cannot overtake the start it follows.
        private func bind(innerRepository: CommonJointAccountsRepository) {
            let publisher = Publishers
                .CombineLatest3(
                    innerRepository.jointAccountsPendingOperationsPublisher,
                    innerRepository.jointAccountsPublisher,
                    frequentUpdatesRequestsCountSubject
                )
                .map(Self.pollingMode(pendingOperations:accounts:frequentUpdatesRequestsCount:))
                .removeDuplicates()

            pollingModeSubscription = Task { [weak self] in
                for await mode in await publisher.values {
                    await self?.updatePolling(mode: mode)
                }
            }

            foregroundSubscription = NotificationCenter.default
                .publisher(for: UIApplication.willEnterForegroundNotification)
                .sink { [weak innerRepository] _ in
                    innerRepository?.initialize()
                }
        }

        private func updatePolling(mode: PollingMode) async {
            switch mode {
            case .idle:
                await regularPollingProcessor.cancel()
                await frequentPollingProcessor.cancel()
            case .regular:
                await frequentPollingProcessor.cancel()
                await startPolling(with: regularPollingProcessor, runsImmediately: false)
            case .frequent:
                await regularPollingProcessor.cancel()
                await startPolling(with: frequentPollingProcessor, runsImmediately: true)
            }
        }

        private func startPolling(with processor: RepeatedTaskProcessor, runsImmediately: Bool) async {
            // The failure is logged by the load itself, and the next run is the retry
            await processor.start(runsImmediately: runsImmediately) { [weak innerRepository] in
                try? await innerRepository?.loadJointAccountsFromRemote()
            }
        }
    }
}

// MARK: - Auxiliary types

extension CommonJointAccountsRepository.JointAccountsRepositoryAutoupdater {
    enum PollingMode {
        case idle
        case regular
        case frequent
    }
}
