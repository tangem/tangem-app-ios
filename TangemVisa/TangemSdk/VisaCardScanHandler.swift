//
//  VisaCardScanHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemSdk

/// Task for first tap of Visa card. This scan handler decides what to do with scanned Visa card. There are several options:
///  - 1. Empty card - no wallet. This means that card didn't started activation at all and must go through all activation process. No need to other checks
///  - 2. Card with created wallet. Card already started activation and second tap was executed. Here we have two possibilities:
///      - 2.1. Card fully finished activation process. To check this - we need to load authorization challenge for card wallet and sign it
///           If BFF returns authorization tokens for this signature we can finish scan process and return this tokens with `activated` state
///      - 2.2. Card didn't finish activation process. If BFF didn't returned authorization tokens during 2.1, we need to reqeust authorization challenge
///           sign it with card key and request authorization tokens. After receiving activation authorization tokens, handler will request state of activation
///           process from BFF and navigate user to target step to continue activation process.
public final class VisaCardScanHandler: CardSessionRunnable {
    public typealias Response = VisaCardActivationLocalState
    public typealias CompletionHandler = CompletionResult<VisaCardActivationLocalState>

    private let visaUtilities: VisaUtilities
    private let authorizationService: VisaAuthorizationService
    private let cardActivationStateProvider: VisaCardActivationStatusService
    private let visaRefreshTokenRepository: VisaRefreshTokenRepository

    init(
        isTestnet: Bool,
        authorizationService: VisaAuthorizationService,
        cardActivationStateProvider: VisaCardActivationStatusService,
        refreshTokenRepository: VisaRefreshTokenRepository
    ) {
        visaUtilities = .init(isTestnet: isTestnet)
        self.authorizationService = authorizationService
        self.cardActivationStateProvider = cardActivationStateProvider
        visaRefreshTokenRepository = refreshTokenRepository
    }

    deinit {
        VisaLogger.info("Scan handler deinitialized")
    }

    public func run(in session: CardSession, completion: @escaping CompletionHandler) {
        VisaLogger.info("Attempting to handle Visa card scan")
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let mandatoryCurve = visaUtilities.mandatoryCurve
        guard let wallet = card.wallets.first(where: { $0.curve == mandatoryCurve }) else {
            // 1 flow
            let activationInput = VisaCardActivationInput(cardId: card.cardId, cardPublicKey: card.cardPublicKey, isAccessCodeSet: card.isAccessCodeSet)
            let activationStatus = VisaCardActivationLocalState.notStartedActivation(activationInput: activationInput)
            completion(.success(activationStatus))
            return
        }

        // Start of 2 flow
        deriveKey(wallet: wallet, in: session, completion: completion)
    }

    private func deriveKey(wallet: Card.Wallet, in session: CardSession, completion: @escaping CompletionHandler) {
        guard let derivationPath = visaUtilities.visaDefaultDerivationPath else {
            VisaLogger.info("Failed to create derivation path while first scan")
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
                VisaLogger.info("Start task for loading challenge for Visa wallet")
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
        VisaLogger.info("Started handling authorization using Visa wallet")
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let derivationPath = visaUtilities.visaDefaultDerivationPath else {
            VisaLogger.info("Failed to create derivation path while handling wallet authorization")
            completion(.failure(.underlying(error: HandlerError.failedToCreateDerivationPath)))
            return
        }

        guard
            let wallet = card.wallets.first(where: { $0.curve == visaUtilities.mandatoryCurve }),
            let extendedPublicKey = wallet.derivedKeys[derivationPath]
        else {
            VisaLogger.info("Failed to find extended public key while handling wallet authorization")
            completion(.failure(.underlying(error: HandlerError.failedToFindDerivedWalletKey)))
            return
        }

        do {
            VisaLogger.info("Requesting challenge for wallet authorization")
            let walletAddress = try visaUtilities.makeAddress(seedKey: wallet.publicKey, extendedKey: extendedPublicKey)
            let challengeResponse = try await authorizationService.getWalletAuthorizationChallenge(
                cardId: card.cardId,
                walletAddress: walletAddress.value
            )

            let signedChallengeResponse = try await signChallengeWithWallet(
                walletPublicKey: wallet.publicKey,
                derivationPath: derivationPath,
                // Will be changed later after backend implementation
                challenge: Data(hexString: challengeResponse.nonce),
                in: session
            )

            VisaLogger.info("Challenge signed with Wallet public key")

            let authorizationTokensResponse = try await authorizationService.getAccessTokensForWalletAuth(
                signedChallenge: signedChallengeResponse.signature.hexString,
                sessionId: challengeResponse.sessionId
            )

            if let authorizationTokensResponse {
                // 2.1 Flow
                VisaLogger.info("Authorized using Wallet public key successfully")
                try visaRefreshTokenRepository.save(refreshToken: authorizationTokensResponse.refreshToken, cardId: card.cardId)
                completion(.success(.activated(authTokens: authorizationTokensResponse)))
            } else {
                // 2.2 Flow
                VisaLogger.info("Failed to get Access token for Wallet public key authoziation. Authorizing using Card Pub key")
                await handleCardAuthorization(
                    walletAddress: walletAddress.value,
                    session: session,
                    completion: completion
                )
            }
        } catch let error as TangemSdkError {
            VisaLogger.info("Error during Wallet authorization process. Tangem Sdk Error: \(error)")
            completion(.failure(error))
        } catch {
            VisaLogger.info("Error during Wallet authorization process. Error: \(error)")
            completion(.failure(.underlying(error: error)))
        }
    }

    private func handleCardAuthorization(
        walletAddress: String,
        session: CardSession,
        completion: @escaping CompletionHandler
    ) async {
        VisaLogger.info("Started handling visa card scan async")
        guard let card = session.environment.card else {
            VisaLogger.info("Failed to find card in session environment")
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }

        do {
            VisaLogger.info("Requesting authorization challenge to sign")
            let challengeResponse = try await authorizationService.getCardAuthorizationChallenge(
                cardId: card.cardId,
                cardPublicKey: card.cardPublicKey.hexString
            )
            VisaLogger.info("Received challenge to sign")

            let attestCardKeyResponse = try await signChallengeWithCard(session: session, challenge: challengeResponse.nonce)
            VisaLogger.info("Challenged signed. Result: \(attestCardKeyResponse.cardSignature.hexString)")
            let authorizationTokensResponse = try await authorizationService.getAccessTokensForCardAuth(
                signedChallenge: attestCardKeyResponse.cardSignature.hexString,
                salt: attestCardKeyResponse.salt.hexString,
                sessionId: challengeResponse.sessionId
            )
            VisaLogger.info("Receive authorization tokens response")

            let cardActivationStatus = try await cardActivationStateProvider.getCardActivationStatus(
                authorizationTokens: authorizationTokensResponse,
                cardId: card.cardId,
                cardPublicKey: card.cardPublicKey.hexString
            )

            switch cardActivationStatus.activationRemoteState {
            case .blockedForActivation:
                throw VisaActivationError.blockedForActivation
            case .activated:
                throw VisaActivationError.invalidActivationState
            default:
                break
            }

            let activationInput = VisaCardActivationInput(
                cardId: card.cardId,
                cardPublicKey: card.cardPublicKey,
                isAccessCodeSet: card.isAccessCodeSet,
                walletAddress: walletAddress
            )
            completion(.success(.activationStarted(
                activationInput: activationInput,
                authTokens: authorizationTokensResponse,
                activationStatus: cardActivationStatus
            )))
        } catch let error as TangemSdkError {
            VisaLogger.error("Failed to handle challenge signing. Tangem SDK error", error: error)
            completion(.failure(error))
        } catch {
            VisaLogger.error("Failed to handle challenge signing. Plain error", error: error)
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
}

extension VisaCardScanHandler: CustomStringConvertible {
    public var description: String { "VisaCardScanHandler" }
}

public extension VisaCardScanHandler {
    enum HandlerError: Error, LocalizedError {
        case failedToCreateDerivationPath
        case failedToFindWallet
        case failedToFindDerivedWalletKey

        public var errorDescription: String? {
            switch self {
            case .failedToCreateDerivationPath, .failedToFindWallet, .failedToFindDerivedWalletKey:
                return "Error occurred. Please contact support"
            }
        }
    }
}
