//
//  MultipleSignTask.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation
import TangemSdk
import BlockchainSdk
import TangemFoundation

final class MultipleSignTask: CardSessionRunnable {
    private let dataProvider: () async throws -> [SignData]
    private let seedKey: Data
    private let pairKey: Data?
    private let userWalletRegistrar = CardUserWalletRegistrar(analyticsReporter: CommonBackendAuthenticationNonceAnalyticsReporter())
    private var dataToSign: [SignData] = []

    public convenience init(dataToSign: [SignData], seedKey: Data, pairKey: Data?) {
        self.init(dataProvider: { dataToSign }, seedKey: seedKey, pairKey: pairKey)
    }

    public init(dataProvider: @escaping () async throws -> [SignData], seedKey: Data, pairKey: Data?) {
        self.dataProvider = dataProvider
        self.seedKey = seedKey
        self.pairKey = pairKey
    }

    deinit {
        TSDKLogger.debug("MultipleSignTask deinit")
    }

    public func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>) {
        Task { @MainActor [self] in
            // Obtaining the nonce before the NFC session opens, so the NFC session remains responsive
            async let nonceObtained: Void = withCheckedContinuation { continuation in
                userWalletRegistrar.obtainNonce { continuation.resume() }
            }

            let result: Result<[SignData], Error>
            do {
                result = .success(try await dataProvider())
            } catch {
                result = .failure(error)
            }

            await nonceObtained

            switch result {
            case .success(let data):
                dataToSign = data
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error.toTangemSdkError()))
            }
        }
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<[MultipleSignTaskResponse]>) {
        runSign(at: 0, session: session, partialResult: [], completion: completion)
    }

    private func runSign(
        at index: Int,
        session: CardSession,
        partialResult: [MultipleSignTaskResponse],
        completion: @escaping CompletionResult<[MultipleSignTaskResponse]>
    ) {
        guard index < dataToSign.count else {
            if partialResult.count == dataToSign.count {
                userWalletRegistrar.registerIfNeeded(in: session) {
                    completion(.success(partialResult))
                }
            } else {
                completion(.failure(TangemSdkError.signHashesNotAvailable))
            }
            return
        }

        let signData = dataToSign[index]

        let signCommand = SignAndReadTask(
            hashes: signData.hashes,
            seedKey: seedKey,
            pairWalletPublicKey: pairKey,
            hdKey: signData.derivationPath.map {
                .init(blockchainKey: signData.publicKey, derivationPath: $0)
            }
        )

        signCommand.run(in: session) { result in
            switch result {
            case .success(let signResponse):
                var partialResult = partialResult
                guard signResponse.signatures.count == signData.hashes.count else {
                    completion(.failure(TangemSdkError.signHashesNotAvailable))
                    return
                }
                partialResult.append(
                    MultipleSignTaskResponse(
                        signatures: signResponse.signatures,
                        card: signResponse.card,
                        publicKey: signResponse.publicKey,
                        hashes: signData.hashes
                    )
                )
                self.runSign(at: index + 1, session: session, partialResult: partialResult, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension MultipleSignTask {
    struct MultipleSignTaskResponse {
        let signatures: [Data]
        let card: Card
        let publicKey: Data
        let hashes: [Data]
    }
}
