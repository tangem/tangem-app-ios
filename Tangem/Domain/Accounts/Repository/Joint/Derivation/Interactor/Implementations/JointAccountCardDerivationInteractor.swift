//
//  JointAccountCardDerivationInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemFoundation

final class JointAccountCardDerivationInteractor {
    private let tangemSdk: TangemSdk
    private let filter: SessionFilter
    private let keysRepository: KeysRepository

    init(config: UserWalletConfig, keysRepository: KeysRepository) {
        tangemSdk = config.makeTangemSdk()
        filter = config.cardSessionFilter
        self.keysRepository = keysRepository
    }
}

// MARK: - JointAccountDerivationInteractor protocol conformance

extension JointAccountCardDerivationInteractor: JointAccountDerivationInteractor {
    func deriveAndSign<Builder: JointAccountPayloadBuilder>(
        derivationIndex: Int,
        payloadBuilder: Builder
    ) async throws -> JointAccountDerivationInteractorResult<Builder.Payload> {
        let seedKey = try keysRepository.masterKeyPublicKey(curve: JointAccountKeyPath.blockchain.curve)
        let task = JointAccountDerivationTask(seedKey: seedKey, derivationIndex: derivationIndex, payloadBuilder: payloadBuilder)

        let response: JointAccountDerivationTask<Builder>.Response = try await withCheckedThrowingContinuation { continuation in
            tangemSdk.startSession(with: task, filter: filter) { result in
                // `run(in:)` returns as soon as it spawns its work, and that work holds the task weakly,
                // so this is what keeps it alive for the session — as at every other session call site
                withExtendedLifetime(task) {}
                continuation.resume(with: result)
            }
        }

        keysRepository.update(derivations: response.derivationResult)

        return JointAccountDerivationInteractorResult(
            payload: response.payload,
            derivedKey: response.derivedKey,
            signature: response.signature
        )
    }
}

// MARK: - Card session task

/// Derives the account's key and signs the payload built around its address within a single NFC session, so that the
/// operation costs one card tap rather than two.
private final class JointAccountDerivationTask<Builder: JointAccountPayloadBuilder>: CardSessionRunnable {
    struct Response {
        let derivationResult: DerivationResult
        let derivedKey: JointAccountDerivedKey
        let payload: Builder.Payload
        let signature: Data
    }

    private let seedKey: Data
    private let derivationIndex: Int
    private let derivationPath: DerivationPath
    private let payloadBuilder: Builder

    init(seedKey: Data, derivationIndex: Int, payloadBuilder: Builder) {
        self.derivationIndex = derivationIndex
        self.seedKey = seedKey
        derivationPath = JointAccountKeyPath.derivationPath(forAccountAtIndex: derivationIndex)
        self.payloadBuilder = payloadBuilder
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<Response>) {
        runTask(in: self, isDetached: false, priority: .userInitiated) { task in
            do {
                let response = try await task.runInternal(in: session)
                completion(.success(response))
            } catch {
                completion(.failure(error.toTangemSdkError()))
            }
        }
    }

    private func runInternal(in session: CardSession) async throws -> Response {
        let derivationResult = try await DeriveMultipleWalletPublicKeysTask([seedKey: [derivationPath]]).run(in: session)

        guard let extendedPublicKey = derivationResult[seedKey]?[derivationPath] else {
            throw Error.keyNotDerived
        }

        let derivedKey = try JointAccountDerivationUtils.makeDerivedKey(
            seedKey: seedKey,
            derivationPath: derivationPath,
            extendedPublicKey: extendedPublicKey
        )

        let payload = payloadBuilder.makePayload(address: derivedKey.address, derivationIndex: derivationIndex)
        let hash = try JointAccountDerivationUtils.digest(payload: payload)

        let signCommand = SignHashCommand(
            hash: hash,
            walletPublicKey: seedKey,
            derivationPath: derivationPath
        )
        let signResponse = try await signCommand.run(in: session)

        let signatureInfo = SignatureInfo(
            signature: signResponse.signature,
            publicKey: derivedKey.publicKey.blockchainKey,
            hash: hash
        )

        return Response(
            derivationResult: derivationResult,
            derivedKey: derivedKey,
            payload: payload,
            signature: try signatureInfo.unmarshal()
        )
    }
}

// MARK: - Error

private extension JointAccountDerivationTask {
    enum Error: String, LocalizedError {
        case keyNotDerived

        var errorDescription: String? {
            switch self {
            case .keyNotDerived: "The derived key is missing from the derivation result."
            }
        }
    }
}
