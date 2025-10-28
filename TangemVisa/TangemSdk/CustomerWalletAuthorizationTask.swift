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

enum CustomerWalletAuthorizationTaskError: Error {
    case derivedKeyNotFound
}

public final class CustomerWalletAuthorizationTask: CardSessionRunnable {
    private let seedKey: Data
    private let authorizationService: VisaAuthorizationService

    public init(seedKey: Data, authorizationService: VisaAuthorizationService) {
        self.seedKey = seedKey
        self.authorizationService = authorizationService
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<Response>) {
        let derivationPath = TangemPayUtilities.derivationPath

        runTask(in: self, isDetached: false, priority: .userInitiated) { handler in
            do {
                let derivationResult = try await DeriveMultipleWalletPublicKeysTask([
                    handler.seedKey: [derivationPath],
                ])
                .run(in: session)

                guard let extendedPublicKey = derivationResult[handler.seedKey]?[derivationPath] else {
                    completion(.failure(.underlying(error: CustomerWalletAuthorizationTaskError.derivedKeyNotFound)))
                    return
                }

                let walletPublicKey = Wallet.PublicKey(
                    seedKey: handler.seedKey,
                    derivationType: .plain(
                        .init(
                            path: derivationPath,
                            extendedPublicKey: extendedPublicKey
                        )
                    )
                )

                let tokens = try await handler.handleCustomerWalletAuthorization(session: session, walletPublicKey: walletPublicKey)
                completion(.success(Response(tokens: tokens, derivationResult: derivationResult)))
            } catch let error as TangemSdkError {
                VisaLogger.info("Error during authorization process. Tangem Sdk Error: \(error)")
                completion(.failure(error))
            } catch {
                VisaLogger.info("Error during authorization process. Error: \(error)")
                completion(.failure(.underlying(error: error)))
            }
        }
    }

    private func handleCustomerWalletAuthorization(session: CardSession, walletPublicKey: Wallet.PublicKey) async throws -> VisaAuthorizationTokens {
        VisaLogger.info("Requesting challenge for wallet authorization")

        let challengeResponse = try await authorizationService.getCustomerWalletAuthorizationChallenge(
            customerWalletAddress: TangemPayUtilities.makeAddress(using: walletPublicKey)
        )

        VisaLogger.info("Received challenge to sign")

        let nonce = challengeResponse.nonce
        let sessionId = challengeResponse.sessionId

        let signingRequestMessage = TangemPayUtilities.makeCustomerWalletSigningRequestMessage(nonce: nonce)
        let eip191Message = TangemPayUtilities.makeEIP191Message(content: signingRequestMessage)

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

public extension CustomerWalletAuthorizationTask {
    struct Response {
        public let tokens: VisaAuthorizationTokens
        public let derivationResult: [Data: DerivedKeys]
    }
}
