//
//  VisaCardScanHandler.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk
import TangemVisa

class VisaCardScanHandler {
    typealias CompletionHandler = CompletionResult<DefaultWalletData>
    private let authorizationService: VisaAuthorizationService
    private let visaUtilities = VisaUtilities()

    init() {
        let builder = VisaAPIServiceBuilder()
        authorizationService = builder.buildAuthorizationService(urlSessionConfiguration: .defaultConfiguration, logger: AppLog.shared)
    }

    deinit {
        log("Scan handler deinitialized")
    }

    func handleVisaCardScan(session: CardSession, completion: @escaping CompletionHandler) {
        log("Attempting to handle Visa card scan")
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let mandatoryCurve = visaUtilities.mandatoryCurve
        guard let wallet = card.wallets.first(where: { $0.curve == mandatoryCurve }) else {
            let activationInput = VisaCardActivationInput(cardId: card.cardId, cardPublicKey: card.cardPublicKey)
            let activationStatus = VisaCardActivationStatus.notStartedActivation(activationInput: activationInput)
            completion(.success(.visa(activationStatus)))
            return
        }

        deriveKey(wallet: wallet, in: session, completion: completion)
    }

    private func deriveKey(wallet: Card.Wallet, in session: CardSession, completion: @escaping CompletionHandler) {
        guard let derivationPath = visaUtilities.visaCardDerivationPath else {
            log("Failed to create derivation path while first scan")
            completion(.failure(.underlying(error: HandlerError.failedToCreateDerivationPath)))
            return
        }

        let derivationTask = DeriveWalletPublicKeyTask(walletPublicKey: wallet.publicKey, derivationPath: derivationPath)
        derivationTask.run(in: session) { result in
            self.handleDerivationResponse(
                derivationResult: result,
                in: session,
                completion: completion
            )
        }
    }

    private func handleDerivationResponse(
        derivationResult: Result<ExtendedPublicKey, TangemSdkError>,
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) {
        switch derivationResult {
        case .success:
            runTask(in: self, isDetached: false, priority: .userInitiated) { handler in
                handler.log("Start task for loading challenge for Visa wallet")
                await handler.handleWalletAuthorization(in: session, completion: completion)
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

    private func handleWalletAuthorization(
        in session: CardSession,
        completion: @escaping CompletionHandler
    ) async {
        log("Started handling authorization using Visa wallet")
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let derivationPath = visaUtilities.visaCardDerivationPath else {
            log("Failed to create derivation path while handling wallet authorization")
            completion(.failure(.underlying(error: HandlerError.failedToCreateDerivationPath)))
            return
        }

        guard
            let wallet = card.wallets.first(where: { $0.curve == visaUtilities.mandatoryCurve }),
            let extendedPublicKey = wallet.derivedKeys[derivationPath]
        else {
            log("Failed to find extended public key while handling wallet authorization")
            completion(.failure(.underlying(error: HandlerError.failedToFindDerivedWalletKey)))
            return
        }

        do {
            log("Requesting challenge for wallet authorization")
            // Will be changed later after backend implementation
            let challengeResponse = try await authorizationService.getWalletAuthorizationChallenge(
                cardId: card.cardId,
                walletPublicKey: extendedPublicKey.publicKey.hexString
            )

            let signedChallengeResponse = try await signChallengeWithWallet(
                walletPublicKey: wallet.publicKey,
                derivationPath: derivationPath,
                // Will be changed later after backend implementation
                challenge: Data(hexString: challengeResponse.nonce),
                in: session
            )

            log("Challenge signed with Wallet public key")

            let authorizationTokensResponse = try await authorizationService.getAccessTokensForWalletAuth(
                signedChallenge: signedChallengeResponse.signature.hexString,
                sessionId: challengeResponse.sessionId
            )

            if let authorizationTokensResponse {
                log("Authorized using Wallet public key successfully")
                completion(.success(.visa(.activated(authTokens: authorizationTokensResponse))))
            } else {
                log("Failed to get Access token for Wallet public key authoziation. Authorizing using Card Pub key")
                await handleCardAuthorization(session: session, completion: completion)
            }
        } catch let error as TangemSdkError {
            log("Error during Wallet authorization process. Tangem Sdk Error: \(error)")
            completion(.failure(error))
        } catch {
            log("Error during Wallet authorization process. Error: \(error)")
            completion(.failure(.underlying(error: error)))
        }
    }

    private func handleCardAuthorization(session: CardSession, completion: @escaping CompletionHandler) async {
        log("Started handling visa card scan async")
        guard let card = session.environment.card else {
            log("Failed to find card in session environment")
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }

        do {
            log("Requesting authorization challenge to sign")
            let challengeResponse = try await authorizationService.getCardAuthorizationChallenge(
                cardId: card.cardId,
                cardPublicKey: card.cardPublicKey.hexString
            )
            log("Received challenge to sign: \(challengeResponse)")

            let attestCardKeyResponse = try await signChallengeWithCard(session: session, challenge: challengeResponse.nonce)
            log("Challenged signed. Result: \(attestCardKeyResponse.cardSignature.hexString)")
            let authorizationTokensResponse = try await authorizationService.getAccessTokensForCardAuth(
                signedChallenge: attestCardKeyResponse.cardSignature.hexString,
                salt: attestCardKeyResponse.salt.hexString,
                sessionId: challengeResponse.sessionId
            )
            log("Authorization tokens response: \(authorizationTokensResponse)")

            let activationInput = VisaCardActivationInput(cardId: card.cardId, cardPublicKey: card.cardPublicKey)
            let visaWalletData = DefaultWalletData.visa(.activationStarted(
                activationInput: activationInput, authTokens: authorizationTokensResponse
            ))
            completion(.success(visaWalletData))
        } catch let error as TangemSdkError {
            log("Failed to handle challenge signing. Tangem SDK error: \(error.localizedDescription)")
            completion(.failure(error))
        } catch {
            log("Failed to handle challenge signing. Plain error: \(error.localizedDescription)")
            completion(.failure(TangemSdkError.underlying(error: error)))
        }
    }

    private func signChallengeWithWallet(
        walletPublicKey: Data,
        derivationPath: DerivationPath,
        challenge: Data,
        in session: CardSession
    ) async throws -> SignHashResponse {
        try await withCheckedThrowingContinuation { [session] continuation in
            let signHashCommand = SignHashCommand(hash: challenge, walletPublicKey: walletPublicKey, derivationPath: derivationPath)
            signHashCommand.run(in: session) { result in
                switch result {
                case .success(let signHashResponse):
                    continuation.resume(returning: signHashResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func signChallengeWithCard(session: CardSession, challenge: String) async throws -> AttestCardKeyResponse {
        try await withCheckedThrowingContinuation { [session] continuation in
            let data = Data(hexString: challenge)
            let signTask = AttestCardKeyCommand(challenge: data)
            signTask.run(in: session) { result in
                switch result {
                case .success(let attestCardKeyResponse):
                    continuation.resume(returning: attestCardKeyResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        AppLog.shared.debug("[Visa Card Scan Handler] \(message())")
    }
}

extension VisaCardScanHandler {
    enum HandlerError: Error, LocalizedError {
        case failedToCreateDerivationPath
        case failedToFindWallet
        case failedToFindDerivedWalletKey

        var errorDescription: String? {
            switch self {
            case .failedToCreateDerivationPath, .failedToFindWallet, .failedToFindDerivedWalletKey:
                return "Error occurred. Please contact support"
            }
        }
    }
}
