//
//  UserWalletRegistrationTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk
import TangemFoundation

/// A thin generic wrapper around `CardSessionRunnable` that registers a user wallet after the wrapped task has completed successfully.
final class UserWalletRegistrationTask<Wrapped: CardSessionRunnable> {
    private let wrapped: Wrapped
    private let userWalletRegistrar = CardUserWalletRegistrar()

    init(wrapped: Wrapped) {
        self.wrapped = wrapped
    }
}

// MARK: - CardSessionRunnable protocol conformance

extension UserWalletRegistrationTask: CardSessionRunnable {
    typealias Response = Wrapped.Response

    var preflightReadMode: PreflightReadMode { wrapped.preflightReadMode }
    var shouldAskForAccessCode: Bool { wrapped.shouldAskForAccessCode }
    var encryptionMode: EncryptionMode { wrapped.encryptionMode }

    func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>) {
        // Obtaining the nonce before the NFC session opens, so the NFC session remains responsive
        userWalletRegistrar.obtainNonce { [wrapped] in
            wrapped.prepare(session, completion: completion)
        }
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<Response>) {
        wrapped.run(in: session) { [userWalletRegistrar] result in
            switch result {
            case .success(let response):
                userWalletRegistrar.registerIfNeeded(in: session) {
                    completion(.success(response))
                }
            case .failure(let error):
                BackendAuthLogger.error("Skipped user wallet registration (card \(session.environment.card?.cardId ?? .unknown))", error: error)
                completion(result)
            }
        }
    }
}
