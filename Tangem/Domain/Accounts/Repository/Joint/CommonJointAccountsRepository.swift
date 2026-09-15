//
//  CommonJointAccountsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
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

    /// - Note: The contract offers no caching, so the list is asked for often and every asker gets the answer of the
    /// one request that actually goes out.
    private lazy var loadJointAccountsDebouncer = Debouncer<LoadResult>(interval: Constants.debounceInterval) { [weak self] completion in
        guard let self else {
            // The callers wait through continuations, so even a dead repository has to answer rather than hang them
            completion(.failure(CancellationError()))
            return
        }

        loadJointAccountsFromServer(completion)
    }

    private var loadAccountsSubscription: AnyCancellable?

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
        let remoteJointAccounts = try await networkService.getJointAccounts()
        try Task.checkCancellation()

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
    }
}
