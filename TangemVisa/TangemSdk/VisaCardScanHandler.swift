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

    private let authorizationService: VisaAuthorizationService
    private let cardActivationStateProvider: VisaCardActivationStatusService
    private let visaRefreshTokenRepository: VisaRefreshTokenRepository
    private let isTestnet: Bool

    init(
        authorizationService: VisaAuthorizationService,
        cardActivationStateProvider: VisaCardActivationStatusService,
        refreshTokenRepository: VisaRefreshTokenRepository,
        isTestnet: Bool
    ) {
        self.authorizationService = authorizationService
        self.cardActivationStateProvider = cardActivationStateProvider
        visaRefreshTokenRepository = refreshTokenRepository
        self.isTestnet = isTestnet
    }

    deinit {
        VisaLogger.info("Scan handler deinitialized")
    }

    public func run(in session: CardSession, completion: @escaping CompletionHandler) {
        VisaLogger.info("Attempting to handle Visa card scan")
        guard let card = session.environment.card else {
            VisaLogger.info("Failed to find card in session environment")
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let wallet = card.wallets.first(where: { $0.curve == VisaUtilities.mandatoryCurve }) else {
            // 1 flow
            let activationInput = VisaCardActivationInput(
                cardId: card.cardId,
                cardPublicKey: card.cardPublicKey,
                isAccessCodeSet: card.isAccessCodeSet
            )
            let activationStatus = VisaCardActivationLocalState.notStartedActivation(activationInput: activationInput)
            completion(.success(activationStatus))
            return
        }

        // Start of 2 flow
        VisaLogger.info("Start task for loading challenge for Visa wallet")
        runTask(in: self, isDetached: false, priority: .userInitiated) { handler in
            do {
                let cardActivationState = try await handler.handleWalletAuthorizationWithFallbackToCardAuthorization(
                    session: session,
                    card: card,
                    wallet: wallet
                )
                completion(.success(cardActivationState))
            } catch let error as TangemSdkError {
                VisaLogger.info("Error during authorization process. Tangem Sdk Error: \(error)")
                completion(.failure(error))
            } catch {
                VisaLogger.info("Error during authorization process. Error: \(error)")
                completion(.failure(.underlying(error: error)))
            }
        }
    }

    private func handleWalletAuthorizationWithFallbackToCardAuthorization(
        session: CardSession,
        card: Card,
        wallet: Card.Wallet
    ) async throws -> VisaCardActivationLocalState {
        do {
            VisaLogger.info("Started handling authorization using Visa wallet")
            return try await handleWalletAuthorization(
                session: session,
                cardId: card.cardId,
                walletPublicKey: wallet.publicKey
            )
        } catch {
            VisaLogger.info("Started handling visa card scan async")
            let walletAddress = try VisaUtilities.makeAddress(walletPublicKey: wallet.publicKey, isTestnet: isTestnet).value
            return try await handleCardAuthorization(
                session: session,
                cardId: card.cardId,
                cardPublicKey: card.cardPublicKey,
                isAccessCodeSet: card.isAccessCodeSet,
                walletAddress: walletAddress
            )
        }
    }

    private func handleWalletAuthorization(
        session: CardSession,
        cardId: String,
        walletPublicKey: Data
    ) async throws -> VisaCardActivationLocalState {
        VisaLogger.info("Requesting challenge for wallet authorization")
        let challengeResponse = try await authorizationService.getWalletAuthorizationChallenge(
            cardId: cardId,
            walletPublicKey: walletPublicKey.hexString
        )
        VisaLogger.info("Received challenge to sign")

        let signedChallengeResponse = try await AttestWalletKeyTask(
            walletPublicKey: walletPublicKey,
            challenge: Data(hexString: challengeResponse.nonce),
            confirmationMode: .dynamic
        )
        .run(in: session)
        VisaLogger.info("Challenge signed with Wallet public key")

        let authorizationTokensResponse = try await authorizationService.getAccessTokensForWalletAuth(
            signedChallenge: signedChallengeResponse.walletSignature.hexString,
            salt: signedChallengeResponse.salt.hexString,
            sessionId: challengeResponse.sessionId
        )
        VisaLogger.info("Receive authorization tokens response")

        VisaLogger.info("Authorized using Wallet public key successfully")
        try visaRefreshTokenRepository.save(refreshToken: authorizationTokensResponse.refreshToken, visaRefreshTokenId: .cardId(cardId))

        return .activated(authTokens: authorizationTokensResponse)
    }

    private func handleCardAuthorization(
        session: CardSession,
        cardId: String,
        cardPublicKey: Data,
        isAccessCodeSet: Bool,
        walletAddress: String
    ) async throws -> VisaCardActivationLocalState {
        VisaLogger.info("Requesting challenge for wallet authorization")
        let challengeResponse = try await authorizationService.getCardAuthorizationChallenge(
            cardId: cardId,
            cardPublicKey: cardPublicKey.hexString
        )
        VisaLogger.info("Received challenge to sign")

        let signedChallengeResponse = try await AttestCardKeyCommand(
            challenge: Data(hexString: challengeResponse.nonce)
        )
        .run(in: session)
        VisaLogger.info("Challenge signed with Wallet public key")

        let authorizationTokensResponse = try await authorizationService.getAccessTokensForCardAuth(
            signedChallenge: signedChallengeResponse.cardSignature.hexString,
            salt: signedChallengeResponse.salt.hexString,
            sessionId: challengeResponse.sessionId
        )
        VisaLogger.info("Receive authorization tokens response")

        let cardActivationStatus = try await cardActivationStateProvider.getCardActivationStatus(
            cardId: cardId,
            cardPublicKey: cardPublicKey.hexString
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
            cardId: cardId,
            cardPublicKey: cardPublicKey,
            isAccessCodeSet: isAccessCodeSet,
            walletAddress: walletAddress
        )

        return .activationStarted(
            activationInput: activationInput,
            authTokens: authorizationTokensResponse,
            activationStatus: cardActivationStatus
        )
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

public extension CardSessionRunnable {
    func run(in session: CardSession) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            self.run(in: session) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }
}
