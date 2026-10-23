//
//  DeriveAndRunCardTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk

final class DeriveAndRunCardTask<Output>: CardSessionRunnable {
    typealias Response = Output
    typealias Work = (_ session: CardSession, _ derivedKey: ExtendedPublicKey) async throws -> Output

    private let seedKey: Data
    private let derivationPath: DerivationPath
    private let keysRepository: KeysRepository
    private let timeout: Duration
    private let mapError: (Error) -> TangemSdkError
    private let work: Work

    init(
        seedKey: Data,
        derivationPath: DerivationPath,
        keysRepository: KeysRepository,
        timeout: Duration = .seconds(20),
        mapError: @escaping (Error) -> TangemSdkError,
        work: @escaping Work
    ) {
        self.seedKey = seedKey
        self.derivationPath = derivationPath
        self.keysRepository = keysRepository
        self.timeout = timeout
        self.mapError = mapError
        self.work = work
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<Response>) {
        runTask(in: self, priority: .userInitiated) { task in
            do {
                let response = try await Task.run(withTimeout: task.timeout) {
                    try await task.runInternal(in: session)
                }
                completion(.success(response))
            } catch {
                completion(.failure(task.mapError(error)))
            }
        }
    }

    private func runInternal(in session: CardSession) async throws -> Output {
        let derivations = try await DeriveMultipleWalletPublicKeysTask(
            [seedKey: [derivationPath]],
            shouldFailIfNothingDerived: true
        )
        .run(in: session)

        guard let derivedKey = derivations[seedKey]?[derivationPath] else {
            throw DeriveAndRunCardTaskError.keyNotDerived
        }

        keysRepository.update(derivations: derivations)

        return try await work(session, derivedKey)
    }
}

enum DeriveAndRunCardTaskError: Error {
    case keyNotDerived
}
