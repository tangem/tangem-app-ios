//
//  CustomerWalletAuthorizationTask.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation
import TangemSdk

public final class CustomerWalletAuthorizationTask: CardSessionRunnable {
    private let authorizationService: VisaAuthorizationService
    private let walletPublicKey: Wallet.PublicKey
    private let walletAddress: String

    public init(
        walletPublicKey: Wallet.PublicKey,
        walletAddress: String,
        authorizationService: VisaAuthorizationService
    ) {
        self.walletPublicKey = walletPublicKey
        self.walletAddress = walletAddress
        self.authorizationService = authorizationService
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<VisaAuthorizationTokens>) {
        runTask(in: self, isDetached: false, priority: .userInitiated) { handler in
            do {
                let tokens = try await handler.handleCustomerWalletAuthorization(session: session)
                completion(.success(tokens))
            } catch let error as TangemSdkError {
                VisaLogger.info("Error during authorization process. Tangem Sdk Error: \(error)")
                completion(.failure(error))
            } catch {
                VisaLogger.info("Error during authorization process. Error: \(error)")
                completion(.failure(.underlying(error: error)))
            }
        }
    }

    private func handleCustomerWalletAuthorization(session: CardSession) async throws -> VisaAuthorizationTokens {
        VisaLogger.info("Requesting challenge for wallet authorization")
        let challengeResponse = try await authorizationService.getCustomerWalletAuthorizationChallenge(
            customerWalletAddress: walletAddress
        )
        VisaLogger.info("Received challenge to sign")

        let nonce = challengeResponse.nonce
        let sessionId = challengeResponse.sessionId

        let signingRequestMessage = VisaUtilities.makeCustomerWalletSigningRequestMessage(nonce: nonce)
        let eip191Message = VisaUtilities.makeEIP191Message(content: signingRequestMessage)

        guard let eip191MessageData = eip191Message.data(using: .utf8) else {
            throw VisaUtilitiesError.failedToCreateEIP191Message(content: signingRequestMessage)
        }

        let hash = eip191MessageData.sha3(.keccak256)

        let signResponse = try await SignHashCommand(
            hash: hash,
            walletPublicKey: walletPublicKey.seedKey,
            derivationPath: walletPublicKey.derivationPath
        )
        .run(in: session)
        VisaLogger.info("Challenge signed with customer wallet public key")

        let unmarshalledSignature = try Secp256k1Signature(with: signResponse.signature).unmarshal(
            with: walletPublicKey.blockchainKey,
            hash: hash
        )

        let authorizationTokensResponse = try await authorizationService.getAccessTokensForCustomerWalletAuth(
            sessionId: sessionId,
            signedChallenge: unmarshalledSignature.data.hexString,
            messageFormat: signingRequestMessage
        )
        VisaLogger.info("Receive authorization tokens response")

        return authorizationTokensResponse
    }
}
