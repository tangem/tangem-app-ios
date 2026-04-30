//
//  CustomerWalletAuthorizationTask.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemSdk
import TangemPay
import TangemVisa

public final class CustomerWalletAuthorizationTask: CardSessionRunnable {
    private let customerWalletId: String
    private let authorizationService: TangemPayAuthorizationService
    private let pendingDerivations: [Data: [DerivationPath]]

    public init(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService,
        pendingDerivations: [Data: [DerivationPath]]
    ) {
        self.customerWalletId = customerWalletId
        self.authorizationService = authorizationService
        self.pendingDerivations = pendingDerivations
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<Response>) {
        runTask(in: self, isDetached: false, priority: .userInitiated) { handler in
            var derivationResult: DerivationResult = [:]

            do {
                var combinedPendingDerivations = handler.pendingDerivations

                let derivationPath = TangemPayUtilities.derivationPath
                let wallets = session.environment.card?.wallets
                let seedKey = wallets?.first(where: { $0.curve == TangemPayUtilities.mandatoryCurve })?.publicKey

                // Proceed with derivation even without the TangemPay seed key,
                // so that other pending derivations are not blocked
                if let seedKey {
                    combinedPendingDerivations[seedKey, default: []].append(derivationPath)
                }

                derivationResult = try await DeriveMultipleWalletPublicKeysTask(combinedPendingDerivations).run(in: session)

                guard let seedKey, let extendedPublicKey = derivationResult[seedKey]?[derivationPath] else {
                    throw CustomerWalletAuthorizationTaskError.derivedKeyNotFound
                }

                let walletPublicKey = Wallet.PublicKey(
                    seedKey: seedKey,
                    derivationType: .plain(
                        .init(
                            path: derivationPath,
                            extendedPublicKey: extendedPublicKey
                        )
                    )
                )

                let customerWalletAddress = try TangemPayUtilities.makeAddress(using: walletPublicKey)
                let tokens = try await handler.handleCustomerWalletAuthorization(
                    session: session,
                    walletPublicKey: walletPublicKey,
                    customerWalletAddress: customerWalletAddress
                )

                completion(.success(Response(
                    customerWalletAddress: customerWalletAddress,
                    tokens: tokens,
                    derivationResult: derivationResult
                )))
            } catch {
                VisaLogger.info("Error during authorization process. Error: \(error)")
                completion(.success(Response(authorizationError: error, derivationResult: derivationResult)))
            }
        }
    }

    private func handleCustomerWalletAuthorization(
        session: CardSession,
        walletPublicKey: Wallet.PublicKey,
        customerWalletAddress: String
    ) async throws -> TangemPayAuthorizationTokens {
        VisaLogger.info("Requesting challenge for wallet authorization")

        let challengeResponse = try await authorizationService.getChallenge(
            customerWalletAddress: customerWalletAddress,
            customerWalletId: customerWalletId
        )

        VisaLogger.info("Received challenge to sign")

        let signRequest = try TangemPayUtilities.prepareForSign(challengeResponse: challengeResponse)

        let signResponse = try await SignHashCommand(
            hash: signRequest.hash,
            walletPublicKey: walletPublicKey.seedKey,
            derivationPath: walletPublicKey.derivationPath
        )
        .run(in: session)

        VisaLogger.info("Challenge signed with customer wallet public key")

        let unmarshalledSignature = try Secp256k1Signature(with: signResponse.signature).unmarshal(
            with: walletPublicKey.blockchainKey,
            hash: signRequest.hash
        )

        let authorizationTokensResponse = try await authorizationService.getTokens(
            sessionId: challengeResponse.sessionId,
            signedChallenge: unmarshalledSignature.data.hexString,
            messageFormat: signRequest.message
        )

        VisaLogger.info("Receive authorization tokens response")

        return authorizationTokensResponse
    }
}

public extension CustomerWalletAuthorizationTask {
    struct Response {
        public let authorizationResult: Result<AuthorizationData, Error>
        public let derivationResult: [Data: DerivedKeys]

        init(customerWalletAddress: String, tokens: TangemPayAuthorizationTokens, derivationResult: [Data: DerivedKeys]) {
            authorizationResult = .success(AuthorizationData(customerWalletAddress: customerWalletAddress, tokens: tokens))
            self.derivationResult = derivationResult
        }

        init(authorizationError: Error, derivationResult: [Data: DerivedKeys]) {
            authorizationResult = .failure(authorizationError)
            self.derivationResult = derivationResult
        }
    }

    struct AuthorizationData {
        public let customerWalletAddress: String
        public let tokens: TangemPayAuthorizationTokens
    }
}

enum CustomerWalletAuthorizationTaskError: Error {
    case derivedKeyNotFound
}
