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
public final class CreateWalletTask: CardSessionPreflightRunnable {
    public typealias CommandResponse = CreateWalletResponse
    
    public func run(session: CommandTransiever, viewDelegate: CardManagerDelegate, environment: CardEnvironment, currentCard: Card, completion: @escaping CompletionResult<CreateWalletResponse>) {
        
        guard let curve = currentCard.curve else {
            completion(.failure(.cardError))
            return
        }
        
        session.sendCommand(CreateWalletCommand(), environment: environment) { result in
            switch result {
            case .success(let createWalletResponse):
                if createWalletResponse.status == .loaded {
                    guard let checkWalletCommand = CheckWalletCommand(curve: curve, publicKey: createWalletResponse.walletPublicKey) else {
                        completion(.failure(.errorProcessingCommand))
                        return
                    }
                    
                    session.sendCommand(checkWalletCommand, environment: environment) { checkWalletResult in
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
