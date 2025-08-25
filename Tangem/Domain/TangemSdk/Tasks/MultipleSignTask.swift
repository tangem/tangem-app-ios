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

class MultipleSignTask: CardSessionRunnable {
    private let dataToSign: [SignData]
    private let seedKey: Data

    public init(dataToSign: [SignData], seedKey: Data) {
        self.dataToSign = dataToSign
        self.seedKey = seedKey
    }

    deinit {
        TSDKLogger.debug("MultipleSignTask deinit")
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
                completion(.success(partialResult))
            } else {
                completion(.failure(TangemSdkError.signHashesNotAvailable))
            }
            return
        }

        let signData = dataToSign[index]

        let signCommand = SignAndReadTask(
            hashes: [signData.hash],
            seedKey: seedKey,
            pairWalletPublicKey: nil,
            hdKey: signData.derivationPath.map {
                .init(blockchainKey: signData.publicKey, derivationPath: $0)
            }
        )

        signCommand.run(in: session) { result in
            switch result {
            case .success(let signResponse):
                var partialResult = partialResult
                guard let signature = signResponse.signatures.first else {
                    completion(.failure(TangemSdkError.signHashesNotAvailable))
                    return
                }
                partialResult.append(
                    MultipleSignTaskResponse(
                        signature: signature,
                        card: signResponse.card,
                        publicKey: signData.publicKey
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
        let signature: Data
        let card: Card
        let publicKey: Data
    }
}
