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
        deteleWallets(in: session, completion: completion)
    }
    
    private func deteleWallets(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let wallet = session.environment.card?.wallets.last else {
            resetBackup(in: session, completion: completion)
            return
        }
        
        PurgeWalletCommand(publicKey: wallet.publicKey).run(in: session) { result in
            switch result {
            case .success:
                self.deteleWallets(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func resetBackup(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let backupStatus = session.environment.card?.backupStatus,
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
