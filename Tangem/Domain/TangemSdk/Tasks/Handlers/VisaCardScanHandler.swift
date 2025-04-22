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

class VisaCardScanHandler: CardSessionRunnable {
    typealias Response = VisaCardActivationLocalState
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    typealias CompletionHandler = CompletionResult<VisaCardActivationLocalState>
    private let authorizationService: VisaAuthorizationService
    private let cardActivationStateProvider: VisaCardActivationStatusService
    private let visaUtilities = VisaUtilities()

    init() {
        let featureStorage = FeatureStorage.instance
        let apiType = featureStorage.visaAPIType
        let isMockedAPI = featureStorage.isVisaAPIMocksEnabled
        authorizationService = VisaAPIServiceBuilder(
            apiType: apiType,
            isMockedAPIEnabled: isMockedAPI
        )
        .buildAuthorizationService(urlSessionConfiguration: .defaultConfiguration)

        cardActivationStateProvider = VisaCardActivationStatusServiceBuilder(
            apiType: apiType,
            isMockedAPIEnabled: isMockedAPI
        )
        .build(urlSessionConfiguration: .defaultConfiguration)
    }

    deinit {
        VisaLogger.info("Scan handler deinitialized")
    }

    func run(in session: CardSession, completion: @escaping CompletionHandler) {
        VisaLogger.info("Attempting to handle Visa card scan")
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let mandatoryCurve = visaUtilities.mandatoryCurve
        guard let wallet = card.wallets.first(where: { $0.curve == mandatoryCurve }) else {
            let activationInput = VisaCardActivationInput(cardId: card.cardId, cardPublicKey: card.cardPublicKey, isAccessCodeSet: card.isAccessCodeSet)
            let activationStatus = VisaCardActivationLocalState.notStartedActivation(activationInput: activationInput)
            completion(.success(activationStatus))
            return
        }

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
                VisaLogger.info("Authorized using Wallet public key successfully")
                try visaRefreshTokenRepository.save(refreshToken: authorizationTokensResponse.refreshToken, cardId: card.cardId)
                completion(.success(.activated(authTokens: authorizationTokensResponse)))
            } else {
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
    var description: String { "VisaCardScanHandler" }
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
