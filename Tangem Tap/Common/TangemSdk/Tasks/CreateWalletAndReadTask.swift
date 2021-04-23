//
//  CreateWalletAndReadTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class CreateWalletAndReadTask: CardSessionRunnable, PreflightReadCapable {
    typealias CommandResponse = Card
    
    public var preflightReadSettings: PreflightReadSettings { .fullCardRead }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        if let fw = session.environment.card?.firmwareVersion, fw.major < 4 {
            createLegacyWallet(in: session, completion: completion)
        } else {
            createMultiWallet(in: session, completion: completion)
        }
    }
    
    private func createMultiWallet(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        let createWalletCommand = CreateMultiWalletTask()
        createWalletCommand.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                self.scanCard(session: session, completion: completion)
            }
        }
    }
    
    private func createLegacyWallet(in session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        let createWalletCommand = CreateWalletCommand(config: nil, walletIndex: 0)
        createWalletCommand.run(in: session) { createWalletCompletion in
            switch createWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                 self.scanCard(session: session, completion: completion)
            }
        }
    }
    
    private func scanCard(session: CardSession, completion: @escaping CompletionResult<CommandResponse>) {
        let scanTask = PreflightReadTask(readSettings: .fullCardRead)
        scanTask.run(in: session, completion: completion)
    }
}
