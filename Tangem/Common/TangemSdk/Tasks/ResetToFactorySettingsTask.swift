//
//  ResetToFactorySettingsTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class ResetToFactorySettingsTask: CardSessionRunnable {
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        deteleWallets(card: card, in: session, completion: completion)
    }
    
    private func deteleWallets(card: Card, in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let wallet = card.wallets.last else {
            resetBackup(card: card, in: session, completion: completion)
            return
        }
        
        PurgeWalletCommand(publicKey: wallet.publicKey).run(in: session) { result in
            switch result {
            case .success:
                self.deteleWallets(card: card, in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func resetBackup(card: Card, in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let backupStatus = card.backupStatus,
              backupStatus != .noBackup else {
                  completion(.success(session.environment.card!))
                  return
        }
        
        ResetBackupCommand().run(in: session) { result in
            switch result {
            case .success:
                completion(.success(session.environment.card!))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
