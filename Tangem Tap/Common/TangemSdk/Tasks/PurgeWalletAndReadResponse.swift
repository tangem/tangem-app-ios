//
//  PurgeWalletAndReadResponse.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class PurgeWalletAndReadTask: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode { .readWallet(publicKey: publicKey) }
    
    let publicKey: Data
    private var purgeWalletCommand: PurgeWalletCommand? = nil
    
    init(publicKey: Data) {
        self.publicKey = publicKey
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        purgeWalletCommand = PurgeWalletCommand(publicKey: publicKey)
        purgeWalletCommand!.run(in: session) { purgeWalletCompletion in
            switch purgeWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(session.environment.card!))
            }
        }
    }
}
