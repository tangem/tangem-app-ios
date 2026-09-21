//
//  CollectiblesDeriveAndSignTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

/// Derives the cold key and signs a message built around it in one NFC session, so the pair costs one tap.
final class CollectiblesDeriveAndSignTask: CardSessionRunnable {
    struct Response {
        let derivationResult: DerivationResult
        let coldOwner: Data
        let signature: Data
    }

    private let seedKey: Data
    private let message: Data
    private let derivationPath = CollectiblesAccountKeyPath.derivationPath

    init(seedKey: Data, message: Data) {
        self.seedKey = seedKey
        self.message = message
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
        let derivationResult = try await DeriveMultipleWalletPublicKeysTask(
            [seedKey: [derivationPath]],
            shouldFailIfNothingDerived: true
        )
        .run(in: session)

        guard let extendedPublicKey = derivationResult[seedKey]?[derivationPath] else {
            throw Error.keyNotDerived
        }

        let signCommand = SignHashCommand(
            hash: message,
            walletPublicKey: seedKey,
            derivationPath: derivationPath
        )
        let signResponse = try await signCommand.run(in: session)

        return Response(
            derivationResult: derivationResult,
            coldOwner: extendedPublicKey.publicKey,
            signature: signResponse.signature
        )
    }
}

// MARK: - Error

private extension CollectiblesDeriveAndSignTask {
    enum Error: String, LocalizedError {
        case keyNotDerived

        var errorDescription: String? {
            switch self {
            case .keyNotDerived: "The derived key is missing from the derivation result."
            }
        }
    }
}
