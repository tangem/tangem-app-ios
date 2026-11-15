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

    private let analyticsReporter: CommonBackendAuthenticationNonceAnalyticsReporter
    private nonisolated let registrationAnalyticsReporter = UserWalletRegistrationAnalyticsReporter()

    private var nonceTask: NonceTask?
    private var nonceResult: Result<UserWalletRegistrationNonce?, ObtainUserWalletRegistrationNonceError>?

    /// - Note: Not actor-protected since we need to access it from nonisolated contexts.
    private let hasObtainedNonce = OSAllocatedUnfairLock(initialState: false)

    private var obtainedNonce: UserWalletRegistrationNonce? {
        switch nonceResult {
        case .success(let success):
            return success
        case .failure,
             .none:
            return nil
        }
    }

    init(analyticsReporter: CommonBackendAuthenticationNonceAnalyticsReporter) {
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
            await self.register(card: card, in: session)
            completion()
        }
    }

    private nonisolated func register(card: Card, in session: CardSession) async {
        let walletPublicKey: Data

        do {
            walletPublicKey = try extractSecp256k1Key(for: card)
        } catch {
            BackendAuthLogger.error("Failed to attest user wallet (card \(card.cardId))", error: error)
            return
        }

        let signer = CardUserWalletRegistrationSigner(session: session, walletPublicKey: walletPublicKey)
        let userWalletId = UserWalletId(with: walletPublicKey)

        // Just an actor hop, no actual await here
        guard let nonce = await obtainedNonce else {
            BackendAuthLogger.warning("Skipped user wallet registration, no nonce yet (card \(card.cardId))")
            await reportNonceFailureIfNeeded(userWalletId: userWalletId)
            return
        }

        do {
            // No request means the user wallet is already registered
            if let request = try await BackendAuthenticationAssembly.attestUserWallet(
                id: userWalletId,
                nonce: nonce,
                recoveryEnrollment: nil,
                signer: signer
            ) {
                BackendAuthLogger.info("Attested user wallet \(userWalletId.stringValue.masked()) (card \(card.cardId))")
                // Submitted in a fire-and-forget fashion
                submitRegistrationRequest(request, userWalletId: userWalletId, cardId: card.cardId)
            }
        } catch {
            BackendAuthLogger.error("Failed to attest user wallet (card \(card.cardId))", error: error)
            registrationAnalyticsReporter.reportFailure(
                walletType: .walletsTypeCold,
                stage: .backendAuthRegistrationStagePrepare,
                reason: "\(error)",
                id: userWalletId
            )
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
            hasObtainedNonce { $0 = true }
            BackendAuthLogger.info("Obtained user wallet registration nonce")

        // nil: the user wallet is already registered
        case .success(.none):
            break

        case .failure(let error):
            BackendAuthLogger.error("Failed to obtain user wallet registration nonce", error: error)
        }
    }

    private func reportNonceFailureIfNeeded(userWalletId: UserWalletId) async {
        let failureReason: String

        switch nonceResult {
        case .none where nonceTask != nil,
             .some(.failure(.clientFailure(.requestNonceTimeout))):
            failureReason = Analytics.ParameterValue.timeout.rawValue
            analyticsReporter.reportColdUserWalletNonceTimeout()

        case .some(.failure(let error)):
            failureReason = "\(error)"

        case .none, .some(.success):
            return
        }

        guard await !BackendAuthenticationAssembly.retrieveUserWalletRegistrationStatus(id: userWalletId) else {
            return
        }

        registrationAnalyticsReporter.reportFailure(
            walletType: .walletsTypeCold,
            stage: .backendAuthRegistrationStageNonce,
            reason: failureReason,
            id: userWalletId
        )
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
        let registrationAnalyticsReporter = registrationAnalyticsReporter

        runTask(priority: .utility) {
            do {
                let result = try await submitUserWalletRegistration(request: request)
                BackendAuthLogger.info("Registered user wallet \(userWalletId.stringValue.masked()) (card \(cardId))")
                registrationAnalyticsReporter.reportResult(result, id: userWalletId)
            } catch {
                BackendAuthLogger.error("Failed to submit user wallet \(userWalletId.stringValue.masked()) registration (card \(cardId))", error: error)
                registrationAnalyticsReporter.reportFailure(
                    walletType: .walletsTypeCold,
                    stage: .backendAuthRegistrationStageSubmit,
                    reason: "\(error)",
                    id: userWalletId
                )
            }
        }
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CardUserWalletRegistrar: CustomStringConvertible {
    nonisolated var description: String {
        objectDescription(self, userInfo: [
            "hasObtainedNonce": hasObtainedNonce { $0 },
        ])
    }
}

// MARK: - Constants

private extension CardUserWalletRegistrar {
    enum Constants {
        static let nonceTimeout: Duration = .seconds(5)
    }
}
