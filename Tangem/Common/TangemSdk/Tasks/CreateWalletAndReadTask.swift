//
//  CreateWalletAndReadTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class CreateWalletAndReadTask: CardSessionRunnable {
    private let curve: EllipticCurve?
    
    private var command: Any? = nil
    
    init(with curve: EllipticCurve?) {
        self.curve = curve
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if let curve = self.curve {
            createLegacyWallet(in: session, curve: curve, on: card, completion: completion)
        } else {
            createMultiWallet(in: session, completion: completion)
        }
    }

    private func createMultiWallet(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        let createWalletCommand = CreateMultiWalletTask()
        self.command = createWalletCommand
        createWalletCommand.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(session.environment.card!))
            }
        }
    }

    private func createLegacyWallet(in session: CardSession, curve: EllipticCurve, on card: Card, completion: @escaping CompletionResult<Card>) {
        let createWalletCommand = CreateWalletTask(curve: curve)
        self.command = createWalletCommand
        
        createWalletCommand.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(session.environment.card!))
            }
        }
    }
}
