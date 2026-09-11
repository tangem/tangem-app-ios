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

    init(
        userWalletId: UserWalletId,
        networkService: JointAccountsNetworkService,
        derivationInteractorFactory: JointAccountDerivationInteractorFactory,
        persistentStorage: JointAccountsPersistentStorage,
        invitesPersistentStorage: JointAccountsInvitesPersistentStorage,
        isJointAccountsAvailable: Bool
    ) {
        self.userWalletId = userWalletId
        self.networkService = networkService
        self.derivationInteractorFactory = derivationInteractorFactory
        self.persistentStorage = persistentStorage
        self.invitesPersistentStorage = invitesPersistentStorage
        self.isJointAccountsAvailable = isJointAccountsAvailable
        // Eager initialization of these lazy properties to ensure that there are no race conditions
        _ = loadJointAccountsDebouncer
        _ = storageDidUpdatePublisher
    }
}

// MARK: - JointAccountsRepository protocol conformance

extension CommonJointAccountsRepository: JointAccountsRepository {
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
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
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

        try persistentStorage.replace(with: accounts)
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
    }
}
