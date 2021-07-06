//
//  PurgeWalletAndReadResponse.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct PurgeWalletAndReadResponse {
    let card: Card
}

class PurgeWalletAndReadTask: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode { .readWallet(publicKey: publicKey) }
    
    let publicKey: Data
    
    init(publicKey: Data) {
        self.publicKey = publicKey
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<PurgeWalletAndReadResponse>) {
        let purgeWalletCommand = PurgeWalletCommand(publicKey: publicKey)
        purgeWalletCommand.run(in: session) { purgeWalletCompletion in
            switch purgeWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                let scanTask = PreflightReadTask(readMode: .fullCardRead, cardId: nil)
                scanTask.run(in: session) { scanCompletion in
                    switch scanCompletion {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let scanResponse):
                        completion(.success(PurgeWalletAndReadResponse(card: scanResponse)))
                    }
                }
            }
        }
    }
}
