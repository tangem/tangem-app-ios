//
//  CreateMultiWalletAndreadtask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class CreateMultiWalletTask: CardSessionRunnable {
    private let curves: [EllipticCurve]
    private let seed: Data?

    init(curves: [EllipticCurve] = [.secp256k1, .ed25519], seed: Data? = nil) {
        self.curves = curves
        self.seed = seed
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        if curves.isEmpty {
            completion(.success(.init(cardId: card.cardId)))
            return
        }

        createWallet(at: 0, session: session, completion: completion)
    }

    private func createWallet(at index: Int, session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        let curve = curves[index]
        let createWalletTask: CreateWalletTask
        if let seed = seed {
            createWalletTask = .init(curve: curve, seed: seed)
        } else {
            createWalletTask = .init(curve: curve)
        }

        createWalletTask.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success(let createWalletResponse):
                if index == self.curves.count - 1 {
                    completion(.success(SuccessResponse(cardId: createWalletResponse.cardId)))
                } else {
                    self.createWallet(at: index + 1, session: session, completion: completion)
                }
            }
        }
    }
}
