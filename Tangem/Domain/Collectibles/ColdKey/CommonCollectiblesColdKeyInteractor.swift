//
//  CommonCollectiblesColdKeyInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import BlockchainSdk
import TangemSdk
import TangemFoundation

/// A card derives the cold key and signs in the same NFC session; a mobile wallet derives without a session
/// at all, so there is nothing to fold and it signs with the key it holds.
final class CommonCollectiblesColdKeyInteractor {
    private let config: UserWalletConfig
    private let keysRepository: KeysRepository
    private let keysDeriving: KeysDeriving
    private let signer: TangemSigner

    private var curve: EllipticCurve {
        CollectiblesAccountKeyPath.curve(for: config.derivationStyle)
    }

    init(
        config: UserWalletConfig,
        keysRepository: KeysRepository,
        keysDeriving: KeysDeriving,
        signer: TangemSigner
    ) {
        self.config = config
        self.keysRepository = keysRepository
        self.keysDeriving = keysDeriving
        self.signer = signer
    }
}

// MARK: - CollectiblesColdKeyInteractor protocol conformance

extension CommonCollectiblesColdKeyInteractor: CollectiblesColdKeyInteractor {
    func derive<Work: CollectiblesColdKeySessionWork>(andRun work: Work) async throws -> Work.Output {
        guard keysDeriving.requiresCard else {
            try await deriveLocally()
            return try await work.run(signer: self)
        }

        return try await deriveInSession(andRun: work)
    }

    func sign(message: Data, coldKey: Wallet.PublicKey) async throws -> Data {
        guard keysDeriving.requiresCard else {
            return try await signWithHeldKey(message: message, coldKey: coldKey)
        }

        return try await deriveInSession(andRun: SignWork(message: message, coldKey: coldKey))
    }
}

// MARK: - Private implementation

private extension CommonCollectiblesColdKeyInteractor {
    func deriveLocally() async throws {
        let derivations = try await keysDeriving
            .deriveKeys(derivations: [try seedKey(): [CollectiblesAccountKeyPath.derivationPath]])

        keysRepository.update(derivations: derivations)
    }

    func deriveInSession<Work: CollectiblesColdKeySessionWork>(andRun work: Work) async throws -> Work.Output {
        let seedKey = try seedKey()
        let derivationPath = CollectiblesAccountKeyPath.derivationPath
        let task = DeriveAndRunCardTask<Work.Output>(
            seedKey: seedKey,
            derivationPath: derivationPath,
            keysRepository: keysRepository,
            timeout: Constants.sessionTimeout,
            mapError: Self.sessionError(from:),
            work: { session, derivedKey in
                try await work.run(signer: SessionSigner(
                    session: session,
                    seedKey: seedKey,
                    derivationPath: derivationPath,
                    coldOwner: derivedKey.publicKey
                ))
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
        }
    }

    func signWithHeldKey(message: Data, coldKey: Wallet.PublicKey) async throws -> Data {
        let signatureInfo = try await signer
            .sign(hash: message, walletPublicKey: coldKey)
            .async()

        return signatureInfo.signature
    }

    func seedKey() throws -> Data {
        try keysRepository.masterKeyPublicKey(curve: curve)
    }
}

// MARK: - Card session

private extension CommonCollectiblesColdKeyInteractor {
    static func sessionError(from error: Error) -> TangemSdkError {
        switch error {
        case let error as TaskTimeoutError:
            CollectiblesLogger.error("Cold key session work did not finish within \(Constants.sessionTimeout)", error: error)
            return .nfcTimeout
        case is ColdKeyError, is DeriveAndRunCardTaskError:
            CollectiblesLogger.error("cold key session failed", error: error)
            return .unknownError
        default:
            return error.toTangemSdkError()
        }
    }
}

private struct SignWork: CollectiblesColdKeySessionWork {
    let message: Data
    let coldKey: Wallet.PublicKey

    func run(signer: any CollectiblesColdKeySigner) async throws -> Data {
        try await signer.sign(message: message, coldKey: coldKey)
    }
}

private struct SessionSigner: CollectiblesColdKeySigner {
    let session: CardSession
    let seedKey: Data
    let derivationPath: DerivationPath
    let coldOwner: Data

    func sign(message: Data, coldKey: Wallet.PublicKey) async throws -> Data {
        guard coldKey.blockchainKey == coldOwner else {
            throw CommonCollectiblesColdKeyInteractor.ColdKeyError.coldOwnerMismatch
        }

        return try await SignHashCommand(hash: message, walletPublicKey: seedKey, derivationPath: derivationPath)
            .run(in: session)
            .signature
    }
}

// MARK: - Error

private extension CommonCollectiblesColdKeyInteractor {
    enum ColdKeyError: Error {
        case coldOwnerMismatch
    }
}

// MARK: - Constants

private extension CommonCollectiblesColdKeyInteractor {
    enum Constants {
        static let sessionTimeout: Duration = .seconds(20)
    }
}
