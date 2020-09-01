//
//  CreateWalletReadTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct PurgeWalletReadTaskResponse: ResponseCodable {
    let card: Card
    let purgeWalletResponse: PurgeWalletResponse
}

final class PurgeWalletReadTask: CardSessionRunnable {
    deinit {
        print("PurgeWalletReadTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<PurgeWalletReadTaskResponse>) {
        PurgeWalletCommand().run(in: session) { result in
            switch result {
            case .success(let response):
                self.readCard(response, session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readCard(_ response: PurgeWalletResponse, session: CardSession, completion: @escaping CompletionResult<PurgeWalletReadTaskResponse>) {
        ReadCommand().run(in: session) { readResult in
            switch readResult {
            case .success(let card):
                completion(.success(PurgeWalletReadTaskResponse(card: card, purgeWalletResponse: response)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

