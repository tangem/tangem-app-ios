//
//  CreateWalletReadTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CreateWalletReadTaskResponse: ResponseCodable {
    let card: Card
    let createWalletResponse: CreateWalletResponse
}

final class CreateWalletReadTask: CardSessionRunnable {
    deinit {
        print("CreateWalletReadTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletReadTaskResponse>) {
        CreateWalletTask().run(in: session) { result in
            switch result {
            case .success(let createWalletResponse):
                self.readCard(createWalletResponse, session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readCard(_ response: CreateWalletResponse, session: CardSession, completion: @escaping CompletionResult<CreateWalletReadTaskResponse>) {
        ReadCommand().run(in: session) { readResult in
            switch readResult {
            case .success(let card):
                completion(.success(CreateWalletReadTaskResponse(card: card, createWalletResponse: response)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

