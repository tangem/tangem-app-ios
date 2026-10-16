//
//  CardUserWalletRegistrar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk
import TangemFoundation
import TangemVisa
import TangemBackendAuthentication

actor CardUserWalletRegistrar {
    private typealias NonceTask = Task<Void, Never>

    private let analyticsReporter: CommonBackendAuthenticationAnalyticsReporter

    private var nonceTask: NonceTask?
    private var nonceResult: Result<UserWalletRegistrationNonce?, ObtainUserWalletRegistrationNonceError>?

    private var obtainedNonce: UserWalletRegistrationNonce? {
        guard case .some(.success(let nonce)) = nonceResult else {
            return nil
        }
        return nonce
    }

    init(analyticsReporter: CommonBackendAuthenticationAnalyticsReporter) {
        self.analyticsReporter = analyticsReporter
    }

    deinit {
        BackendAuthLogger.debug(self, "deinit")
    }

    nonisolated func obtainNonce(completion: @escaping () -> Void) {
        // Strongly capture `self` for the duration of the task to ensure that the completion handler is always called
        runTask(priority: .userInitiated) {
            await self.waitForNonce(timeout: Constants.nonceTimeout)

            // SDK typically calls the completion handler on the main thread
            await runOnMain(completion)
        }
    }

    nonisolated func registerIfNeeded(in session: CardSession, completion: @escaping () -> Void) {
        guard
            let card = session.environment.card,
            shouldRegisterWallet(for: card)
        else {
            completion()
            return
        }

        // Strongly capture `self` for the duration of the task to ensure that the completion handler is always called
        runTask(priority: .userInitiated) {
            do {
                let walletPublicKey = try self.extractSecp256k1Key(for: card)
                let signer = CardUserWalletRegistrationSigner(session: session, walletPublicKey: walletPublicKey)
                let userWalletId = UserWalletId(with: walletPublicKey)

                let nonce = await self.nonceForRegistration() // Just an actor hop, no actual await here

                if let nonce {
                    // No request means the user wallet is already registered
                    if let request = try await BackendAuthenticationAssembly.attestUserWallet(
                        id: userWalletId,
                        nonce: nonce,
                        recoveryEnrollment: nil,
                        signer: signer
                    ) {
                        BackendAuthLogger.info("Attested user wallet \(userWalletId.stringValue) (card \(card.cardId))")
                        // Submitted in a fire-and-forget fashion
                        self.submitRegistrationRequest(request, userWalletId: userWalletId, cardId: card.cardId)
                    }
                } else {
                    BackendAuthLogger.warning("Skipped user wallet registration, no nonce yet (card \(card.cardId))")
                }
            } catch {
                BackendAuthLogger.error("Failed to attest user wallet (card \(card.cardId))", error: error)
            }

            completion()
        }
    }

    private func waitForNonce(timeout: Duration) async {
        let task = getCachedOrMakeNewNonceTask()

        do {
            try await Task.run(withTimeout: timeout) { await task.value }
        } catch is TaskTimeoutError {
            BackendAuthLogger.warning("Gave up waiting for the user wallet registration nonce after \(timeout)")
        } catch is CancellationError {
            // Cancellation of this task should not affect the `getCachedOrMakeNewNonceTask` task, we want it to finish regardless
        } catch {
            BackendAuthLogger.error("Failed waiting for the user wallet registration nonce", error: error)
        }
    }

    private func getCachedOrMakeNewNonceTask() -> NonceTask {
        // Idempotency gate
        if let nonceTask {
            return nonceTask
        }

        // Bare `Task` is used here intentionally to avoid capturing `self` strongly - we don't need nonce if the registrar is deallocated
        let task = NonceTask { [weak self] in
            let result: Result<UserWalletRegistrationNonce?, ObtainUserWalletRegistrationNonceError>

            do throws(ObtainUserWalletRegistrationNonceError) {
                // [REDACTED_TODO_COMMENT]
                let nonce = try await BackendAuthenticationAssembly.obtainUserWalletRegistrationNonce(id: nil)
                result = .success(nonce)
            } catch {
                result = .failure(error)
            }

            await self?.store(result)
        }
        nonceTask = task

        return task
    }

    private func store(_ result: Result<UserWalletRegistrationNonce?, ObtainUserWalletRegistrationNonceError>) {
        nonceResult = result

        switch result {
        case .success(.some):
            BackendAuthLogger.info("Obtained user wallet registration nonce")

        // nil: the user wallet is already registered
        case .success(.none):
            break

        case .failure(let error):
            BackendAuthLogger.error("Failed to obtain user wallet registration nonce", error: error)
        }
    }

    private func nonceForRegistration() -> UserWalletRegistrationNonce? {
        if let obtainedNonce {
            return obtainedNonce
        }

        reportNonceTimeoutIfNeeded()
        return nil
    }

    private func reportNonceTimeoutIfNeeded() {
        let isTimeout: Bool

        switch nonceResult {
        case .none:
            let nonceFetchIsStillInProgress = nonceTask != nil
            isTimeout = nonceFetchIsStillInProgress

        case .some(.failure(.clientFailure(.requestNonceTimeout))):
            isTimeout = true

        case .some(.failure), .some(.success):
            isTimeout = false
        }

        guard isTimeout else { return }

        analyticsReporter.reportColdUserWalletNonceTimeout()
    }

    private nonisolated func shouldRegisterWallet(for card: Card) -> Bool {
        !VisaUtilities.isVisaCard(card) && !TwinCardsUtils.isTwinCard(card)
    }

    private nonisolated func extractSecp256k1Key(for card: Card) throws(UserWalletRegistrationSignerError) -> Data {
        do {
            return try UserWalletRegistrationKeyUtils.walletPublicKeyToRegister(in: card.wallets, cardId: card.cardId)
        } catch {
            throw UserWalletRegistrationSignerError.walletKeyUnavailable(underlying: error)
        }
    }

    private nonisolated func submitRegistrationRequest(
        _ request: UserWalletRegistrationRequest,
        userWalletId: UserWalletId,
        cardId: String
    ) {
        // Strongly capture the use case or the duration of the task to ensure that the registration request is always submitted
        let submitUserWalletRegistration = BackendAuthenticationAssembly.submitUserWalletRegistration

        runTask(priority: .utility) {
            do {
                try await submitUserWalletRegistration(request: request)
                BackendAuthLogger.info("Registered user wallet \(userWalletId.stringValue) (card \(cardId))")
            } catch {
                BackendAuthLogger.error("Failed to submit user wallet \(userWalletId.stringValue) registration (card \(cardId))", error: error)
            }
        }
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CardUserWalletRegistrar: @preconcurrency CustomStringConvertible {
    var description: String {
        objectDescription(
            String(describing: Self.self),
            userInfo: [
                "hasObtainedNonce": obtainedNonce != nil,
            ]
        )
    }
}

// MARK: - Constants

private extension CardUserWalletRegistrar {
    enum Constants {
        static let nonceTimeout: Duration = .seconds(5)
    }
}
