//
//  CardUserWalletLinkTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk
import TangemFoundation
import TangemBackendAuthentication

final class CardUserWalletLinkTask {
    private let nonce: UserWalletRegistrationNonce

    init(nonce: UserWalletRegistrationNonce) {
        self.nonce = nonce
    }
}

// MARK: - CardSessionRunnable protocol conformance

extension CardUserWalletLinkTask: CardSessionRunnable {
    func run(in session: CardSession, completion: @escaping CompletionResult<UserWalletRegistrationRequest?>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        runTask(priority: .userInitiated) { [nonce] in
            do {
                let walletPublicKey = try UserWalletRegistrationKeyUtils.walletPublicKeyToRegister(
                    in: card.wallets,
                    cardId: card.cardId
                )

                let request = try await BackendAuthenticationAssembly.attestUserWallet(
                    id: UserWalletId(with: walletPublicKey),
                    nonce: nonce,
                    recoveryEnrollment: nil,
                    signer: CardUserWalletRegistrationSigner(session: session, walletPublicKey: walletPublicKey)
                )

                completion(.success(request))
            } catch {
                completion(.failure(Self.sdkError(from: error)))
            }
        }
    }
}

// MARK: - Private methods

private extension CardUserWalletLinkTask {
    static func sdkError(from error: Error) -> TangemSdkError {
        guard
            case .signerFailure(.signingFailed(let underlying))? = error as? AttestUserWalletError,
            let sdkError = underlying as? TangemSdkError
        else {
            return error.toTangemSdkError()
        }

        return sdkError
    }
}
