//
//  ScanTask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Task that allows to read Tangem card and verify its private key.
/// It performs `CreateWallet` and `CheckWalletCommand`,  subsequently.
@available(iOS 13.0, *)
public final class CreateWalletTask: CardSessionRunnable {
    public typealias CommandResponse = CreateWalletResponse
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        
        guard let curve = session.environment.card?.curve else {
            completion(.failure(.cardError))
            return
        }
        
        let command = CreateWalletCommand()
        command.run(in: session) { result in
            switch result {
            case .success(let createWalletResponse):
                if createWalletResponse.status == .loaded {
                    guard let checkWalletCommand = CheckWalletCommand(curve: curve, publicKey: createWalletResponse.walletPublicKey) else {
                        completion(.failure(.errorProcessingCommand))
                        return
                    }
                    
                    checkWalletCommand.run(in: session) { checkWalletResult in
                        switch checkWalletResult {
                        case .success(_):
                            completion(.success(createWalletResponse))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                    
                } else {
                    completion(.failure(.errorProcessingCommand))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
