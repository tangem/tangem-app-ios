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
    private let pendingOperationsSynchronizer: JointAccountPendingOperationsSynchronizer
    private let eTagStorage: ETagStorage
    private let isJointAccountsAvailable: Bool

    private lazy var autoupdater = JointAccountsRepositoryAutoupdater(innerRepository: self, isJointAccountsAvailable: isJointAccountsAvailable)
    private var loadAccountsSubscription: AnyCancellable?

    private let storageReadingQueue = DispatchQueue(
        label: "com.tangem.CommonJointAccountsRepository.storageReadingQueue",
        qos: .userInitiated
    )

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
        .receive(on: storageReadingQueue)
        .withWeakCaptureOf(self)
        .map { repository, _ in repository.persistentStorage.getList() }
        .removeDuplicates()
        .receiveOnMain()
        .share(replay: 1)
        .eraseToAnyPublisher()

    init(
        userWalletId: UserWalletId,
        networkService: JointAccountsNetworkService,
        derivationInteractorFactory: JointAccountDerivationInteractorFactory,
        persistentStorage: JointAccountsPersistentStorage,
        pendingOperationsSynchronizer: JointAccountPendingOperationsSynchronizer,
        eTagStorage: ETagStorage,
        isJointAccountsAvailable: Bool
    ) {
        self.userWalletId = userWalletId
        self.networkService = networkService
        self.derivationInteractorFactory = derivationInteractorFactory
        self.persistentStorage = persistentStorage
        self.pendingOperationsSynchronizer = pendingOperationsSynchronizer
        self.eTagStorage = eTagStorage
        self.isJointAccountsAvailable = isJointAccountsAvailable

        // Eager initialization of these lazy properties to ensure that there are no race conditions
        _ = loadJointAccountsDebouncer
        _ = storageDidUpdatePublisher

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

        let account = try await networkService.createJointAccount(blob: blob)

        try persistentStorage.appendNewOrUpdateExisting(StoredJointAccount(remote: account))
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

    func confirmJointAccount(withConfig config: JointAccountConfirmationConfig) async throws -> JointAccountStatus {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let payloadBuilder = JointAccountConfirmationPayloadBuilder(config: config.signedConfig, safeAddress: config.safeAddress)
        let interactor = derivationInteractorFactory.makeInteractor()

        let result = try await interactor.deriveAndSign(
            derivationIndex: config.derivationIndex,
            payloadBuilder: payloadBuilder
        )

        let blob = JointAccountConfirmationBlob(payload: result.payload, signature: result.signature)

        let account = try await networkService.confirmJointAccount(blob: blob)

        try persistentStorage.appendNewOrUpdateExisting(StoredJointAccount(remote: account))

        return account.status
    }

    func issueInvite(cryptoAccountId: String, slot: JointAccountMemberSlotID) async throws -> JointAccountIssuedInvite {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let invite = try await networkService.issueInvite(cryptoAccountId: cryptoAccountId, slot: slot)
        let storedInvite = StoredJointAccount.Invite(slot: invite.slot, expiresAt: invite.expiresAt)

        try persistentStorage.updateInvite(storedInvite, ofAccountWith: cryptoAccountId)

        return invite
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
        let eTagKey = ETagStorageKey.jointAccounts(walletId: userWalletId)
        let hasStoredAccounts = persistentStorage.getList().isNotEmpty
        let knownETag = hasStoredAccounts ? eTagStorage.loadETag(for: eTagKey) : nil
        let pendingOperationsCheckpoint = await pendingOperationsSynchronizer.checkpoint

        let remoteState = try await networkService.getJointAccounts(knownETag: knownETag)
        try Task.checkCancellation()

        guard case .changed(let remoteJointAccounts, let eTag) = remoteState else {
            // Nothing is written: the storage already holds this very list, and rewriting it would only wake
            // every subscriber for nothing
            JointAccountsLogger.debug("The joint accounts have not changed since they were last read")
            return
        }

        JointAccountsLogger.info("Loaded \(remoteJointAccounts.count) joint accounts from API.")
        JointAccountsLogger.debug("Accounts: \(remoteJointAccounts)")

        let accounts = remoteJointAccounts.map(StoredJointAccount.init(remote:))
        let pendingOperations = remoteJointAccounts.compactMap(StoredJointAccountPendingOperations.init(remote:))

        eTagStorage.clearETag(for: eTagKey)

        // The operations go first, so that an account arriving in the list finds what is in flight for it already there
        try await pendingOperationsSynchronizer.apply(listing: pendingOperations, requestedAt: pendingOperationsCheckpoint)
        try persistentStorage.replace(with: accounts)

        let hasLocalWritesSinceRequest = await pendingOperationsSynchronizer.checkpoint != pendingOperationsCheckpoint

        if let eTag, !hasLocalWritesSinceRequest {
            eTagStorage.saveETag(eTag, for: eTagKey)
        }
    }
}

// MARK: - Auxiliary types

extension CommonJointAccountsRepository {
    enum InternalError: Error {
        /// Creating an account is asked for by a screen the feature toggle is supposed to keep out of reach, so this
        /// is a programming error rather than something a user can arrive at.
        case featureUnavailable
    }
}

// MARK: - Constants

private extension CommonJointAccountsRepository {
    enum Constants {
        static let debounceInterval = 0.3
        /// The listing is the only place an account waiting for its members or its activation moves on, so it is re-read
        /// this often until every account has settled.
        static let regularPollingInterval: Duration = .seconds(60)
        static let frequentPollingInterval: Duration = .seconds(5)
    }
}

extension CommonJointAccountsRepository {
    final class JointAccountsRepositoryAutoupdater {
        private weak var innerRepository: CommonJointAccountsRepository?
        private let regularPollingProcessor = RepeatedTaskProcessor(duration: Constants.regularPollingInterval)
        private let frequentPollingProcessor = RepeatedTaskProcessor(duration: Constants.frequentPollingInterval)
        private let frequentUpdatesRequestsCount = OSAllocatedUnfairLock(initialState: 0)
        private let frequentUpdatesRequestsCountSubject = CurrentValueSubject<Int, Never>(0)
        private let pollingModeResolver = PollingModeResolver()

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

        private func changeFrequentUpdatesRequestsCount(by delta: Int) {
            frequentUpdatesRequestsCount.withLockUnchecked { count in
                count += delta
                frequentUpdatesRequestsCountSubject.send(count)
            }
        }

        /// One task reads the publisher in order, so a stop cannot overtake the start it follows.
        private func bind(innerRepository: CommonJointAccountsRepository) {
            let publisher = Publishers
                .CombineLatest(innerRepository.jointAccountsPublisher, frequentUpdatesRequestsCountSubject)
                .map(pollingModeResolver.pollingMode(accounts:frequentUpdatesRequestsCount:))
                .removeDuplicates()

            pollingModeSubscription = Task { [weak self] in
                for await mode in await publisher.values_ {
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

    struct PollingModeResolver {
        func pollingMode(accounts: [StoredJointAccount], frequentUpdatesRequestsCount: Int) -> PollingMode {
            if frequentUpdatesRequestsCount > 0 {
                return .frequent
            }

            let hasPendingAccounts = accounts.contains { account in
                switch account.status {
                case .pending, .confirming: true
                case .active, .untrusted, .cancelled, .unknown: false
                }
            }

            return hasPendingAccounts ? .regular : .idle
        }
    }
}
