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
        let task = DeriveAndRunTask(seedKey: try seedKey(), keysRepository: keysRepository, work: work)
            .withUserWalletRegistration()
        let tangemSdk = config.makeTangemSdk()

        do {
            return try await withCheckedThrowingContinuation { continuation in
                tangemSdk.startSession(with: task, filter: config.cardSessionFilter) { result in
                    withExtendedLifetime(task) {}
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

private final class DeriveAndRunTask<Work: CollectiblesColdKeySessionWork>: CardSessionRunnable {
    typealias Response = Work.Output

    private let seedKey: Data
    private let keysRepository: KeysRepository
    private let work: Work
    private let derivationPath = CollectiblesAccountKeyPath.derivationPath

    init(seedKey: Data, keysRepository: KeysRepository, work: Work) {
        self.seedKey = seedKey
        self.keysRepository = keysRepository
        self.work = work
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<Response>) {
        runTask(in: self, priority: .userInitiated) { task in
            let timeout = CommonCollectiblesColdKeyInteractor.Constants.sessionTimeout

            do {
                let response = try await Task.run(withTimeout: timeout) {
                    try await task.runInternal(in: session)
                }
                completion(.success(response))
            } catch let error as TaskTimeoutError {
                CollectiblesLogger.error("Cold key session work did not finish within \(timeout)", error: error)
                completion(.failure(.nfcTimeout))
            } catch {
                completion(.failure(task.sessionError(from: error)))
            }
        }
    }

    private func runInternal(in session: CardSession) async throws -> Response {
        let derivationResult = try await DeriveMultipleWalletPublicKeysTask(
            [seedKey: [derivationPath]],
            shouldFailIfNothingDerived: true
        )
        .run(in: session)

        guard let extendedPublicKey = derivationResult[seedKey]?[derivationPath] else {
            throw CommonCollectiblesColdKeyInteractor.ColdKeyError.keyNotDerived
        }

        keysRepository.update(derivations: derivationResult)

        let signer = SessionSigner(
            session: session,
            seedKey: seedKey,
            derivationPath: derivationPath,
            coldOwner: extendedPublicKey.publicKey
        )

        return try await work.run(signer: signer)
    }

    private func sessionError(from error: Error) -> TangemSdkError {
        guard let coldKeyError = error as? CommonCollectiblesColdKeyInteractor.ColdKeyError else {
            return error.toTangemSdkError()
        }

        CollectiblesLogger.error("cold key session failed", error: coldKeyError)
        return .unknownError
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
        case keyNotDerived
    }
}

// MARK: - Constants

private extension CommonCollectiblesColdKeyInteractor {
    enum Constants {
        static let sessionTimeout: Duration = .seconds(20)
    }
}
