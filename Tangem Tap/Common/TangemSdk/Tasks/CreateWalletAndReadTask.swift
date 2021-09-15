//
//  CreateWalletAndReadTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class CreateWalletAndReadTask: CardSessionRunnable {
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if card.firmwareVersion.major < 4 {
            createLegacyWallet(in: session, on: card, completion: completion)
        } else {
            if card.isTangemNote {
                createNoteWallet(in: session, on: card, completion: completion)
            } else {
                createMultiWallet(in: session, completion: completion)
            }
        }
    }

    private func createMultiWallet(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        let createWalletCommand = CreateMultiWalletTask()
        createWalletCommand.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(session.environment.card!))
            }
        }
    }

    private func createLegacyWallet(in session: CardSession, on card: Card, completion: @escaping CompletionResult<Card>) {
        guard let supportedCurve = card.supportedCurves.first else {
            completion(.failure(.cardError))
            return
        }
        
        let createWalletCommand = CreateWalletCommand(curve: supportedCurve, isPermanent: card.isPermanentLegacyWallet)
        createWalletCommand.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(session.environment.card!))
            }
        }
    }
    
    private func createNoteWallet(in session: CardSession, on card: Card, completion: @escaping CompletionResult<Card>) {
        guard let targetBlockchain = TangemNote(rawValue: card.batchId)?.blockchain else {
            // [REDACTED_TODO_COMMENT]
            completion(.failure(.underlying(error: "Unknown card batch")))
            return
        }
        
        guard card.supportedCurves.contains(targetBlockchain.curve) else {
            completion(.failure(.underlying(error: "Card doesn't support required curve")))
            return
        }
        
        let createWalletCommand = CreateWalletCommand(curve: targetBlockchain.curve, isPermanent: false)
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
