//
//  CardPolymarketOwnerKeySession.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemPolymarket
import TangemSdk

final class CardPolymarketOwnerKeySession {
    private let config: UserWalletConfig
    private let keysRepository: KeysRepository

    init(config: UserWalletConfig, keysRepository: KeysRepository) {
        self.config = config
        self.keysRepository = keysRepository
    }
}

// MARK: - PolymarketOwnerKeySession protocol conformance

extension CardPolymarketOwnerKeySession: PolymarketOwnerKeySession {
    func derive<Output>(
        andRun work: @escaping (PolymarketOwnerKeySessionContext) async throws -> Output
    ) async throws -> Output {
        let seedKey = try PolymarketUtilities.sessionSeedKey(from: keysRepository, config: config)
        let keysRepository = keysRepository
        let task = DeriveAndRunCardTask<Output>(
            seedKey: seedKey,
            derivationPath: PolymarketUtilities.derivationPath,
            keysRepository: keysRepository,
            timeout: Constants.sessionTimeout,
            mapError: Self.sessionError(from:),
            work: { session, derivedKey in
                let context = try PolymarketOwnerKeySessionContext(
                    ownerKey: PolymarketUtilities.makePublicKey(seedKey: seedKey, derivedKey: derivedKey),
                    keysRepository: keysRepository,
                    signer: SessionSigner(session: session)
                )

                return try await work(context)
            }
        )
        .withUserWalletRegistration()
        let tangemSdk = config.makeTangemSdk()

        do {
            return try await withCheckedThrowingContinuation { continuation in
                tangemSdk.startSession(with: task, filter: config.cardSessionFilter) { result in
                    withExtendedLifetime(task) {}
                    withExtendedLifetime(tangemSdk) {}
                    continuation.resume(with: result)
                }
            }
        } catch TangemSdkError.underlying(let error) {
            throw error
        } catch {
            throw sessionFailure(from: error)
        }
    }
}

// MARK: - Private implementation

private extension CardPolymarketOwnerKeySession {
    static func sessionError(from error: Error) -> TangemSdkError {
        switch error {
        case let error as TaskTimeoutError:
            PolymarketLogger.error("The owner key session did not finish within \(Constants.sessionTimeout)", error: error)
            return .underlying(error: PolymarketOnboardingError.wallet(.upstreamUnavailable(detail: nil)))
        case DeriveAndRunCardTaskError.keyNotDerived:
            PolymarketLogger.error("Derivation succeeded but returned no key", error: PolymarketDerivationError.keyNotDerived)
            return .underlying(error: PolymarketOnboardingError.derivation(.keyNotDerived))
        default:
            return error.toTangemSdkError()
        }
    }

    func sessionFailure(from error: Error) -> PolymarketOnboardingError {
        PolymarketLogger.error("The owner key card session failed", error: error)

        guard PolymarketUtilities.getKey(from: keysRepository) != nil else {
            if !error.isCancellationError {
                Analytics.error(error: error, params: [.action: .deriveKeys])
            }

            return .derivation(PolymarketDerivationError(derivationFailure: error))
        }

        if !error.isCancellationError {
            Analytics.logScanError(error, source: .sign)
        }

        return .signing(PolymarketSigningError(signingFailure: error))
    }
}

// MARK: - Card session

private struct SessionSigner: PolymarketOwnerKeySigner {
    let session: CardSession

    func sign(hashes: [Data], ownerKey: Wallet.PublicKey) async throws -> [SignatureInfo] {
        let response = try await SignHashesCommand(
            hashes: hashes,
            walletPublicKey: ownerKey.seedKey,
            derivationPath: ownerKey.derivationPath
        )
        .run(in: session)

        guard response.signatures.count == hashes.count else {
            throw TangemSdkError.signHashesNotAvailable
        }

        return zip(response.signatures, hashes).map { signature, hash in
            SignatureInfo(signature: signature, publicKey: ownerKey.blockchainKey, hash: hash)
        }
    }
}

// MARK: - Constants

private extension CardPolymarketOwnerKeySession {
    enum Constants {
        static let sessionTimeout: Duration = .seconds(20)
    }
}
