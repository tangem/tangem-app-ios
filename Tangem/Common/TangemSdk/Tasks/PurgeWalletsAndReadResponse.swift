//
//  PurgeWalletAndReadResponse.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class PurgeWalletsAndReadTask: CardSessionRunnable {
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        purgeWallet(index: 0, wallets: card.wallets, in: session, completion: completion)
    }
    
    private func purgeWallet(index: Int, wallets: [Card.Wallet], in session: CardSession, completion: @escaping CompletionResult<Card>) {
        if index >= wallets.count {
            completion(.success(session.environment.card!))
            return
        }
        
        let purgeWalletCommand = PurgeWalletCommand(publicKey: wallets[index].publicKey)
        purgeWalletCommand.run(in: session) { purgeWalletCompletion in
            switch purgeWalletCompletion {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                self.purgeWallet(index: index + 1, wallets: wallets, in: session, completion: completion)
            }
        }
    }
}
