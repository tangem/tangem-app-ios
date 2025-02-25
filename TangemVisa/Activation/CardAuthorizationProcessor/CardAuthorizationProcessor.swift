//
//  AuthorizationProcessor.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardAuthorizationResult {
    let authorizationTokens: VisaAuthorizationTokens
    let cardSession: CardSession
}

protocol CardAuthorizationProcessor {
    func getAuthorizationChallenge(for input: VisaCardActivationInput) async throws -> String
    func getAccessToken(
        signedChallenge: Data,
        salt: Data,
        cardInput: VisaCardActivationInput
    ) async throws -> VisaAuthorizationTokens
}

final class CommonCardAuthorizationProcessor {
    private var authorizationChallengeInput: (sessionId: String, cardInput: VisaCardActivationInput)?

    private let authorizationService: VisaAuthorizationService
    private let logger = InternalLogger(tag: .cardAuthorizationProcessor)

    init(authorizationService: VisaAuthorizationService) {
        self.authorizationService = authorizationService
    }
}

extension CommonCardAuthorizationProcessor: CardAuthorizationProcessor {
    func getAuthorizationChallenge(for input: VisaCardActivationInput) async throws -> String {
        logger.info("Attempting to load authorization challenge")
        let challengeResponse = try await authorizationService.getCardAuthorizationChallenge(
            cardId: input.cardId,
            cardPublicKey: input.cardPublicKey.hexString
        )

        logger.info("Challenge loaded, saving session id")
        authorizationChallengeInput = (sessionId: challengeResponse.sessionId, cardInput: input)
        return challengeResponse.nonce
    }

    func getAccessToken(
        signedChallenge: Data,
        salt: Data,
        cardInput: VisaCardActivationInput
    ) async throws -> VisaAuthorizationTokens {
        guard let authorizationChallengeInput else {
            let error = CardAuthorizationProcessorError.authorizationChallengeNotFound
            logger.error("Failed to find saved authorization challenge input and session", error: error)
            throw error
        }

        guard authorizationChallengeInput.cardInput == cardInput else {
            let error = CardAuthorizationProcessorError.invalidCardInput
            logger.error("Card input in authorization challenge input didn't match with input provided", error: error)
            throw error
        }

        logger.info("Attempting to load access tokens for signed challenge")
        do {
            let accessTokens = try await authorizationService.getAccessTokensForCardAuth(
                signedChallenge: signedChallenge.hexString,
                salt: salt.hexString,
                sessionId: authorizationChallengeInput.sessionId
            )
            return accessTokens
        } catch {
            logger.error("Failed to get access tokens for card authorization", error: error)
            throw CardAuthorizationProcessorError.networkError(error)
        }
    }
}
