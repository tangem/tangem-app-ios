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

    init(curves: [EllipticCurve] = [.secp256k1, .ed25519]) {
        self.curves = curves
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        createWallet(at: 0, session: session, completion: completion)
    }
    
    private func createWallet(at index: Int, session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        let curve = curves[index]
        let createWalletTask = CreateWalletTask(curve: curve/*, isPermanent: false*/)
        createWalletTask.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success(let createWalletResponse):
                if index == self.curves.count - 1 {
                    completion(.success(SuccessResponse(cardId: (createWalletResponse).cardId)))
                } else {
                    self.createWallet(at: index + 1, session: session, completion: completion)
                }
            }
        }
    }
    
}
