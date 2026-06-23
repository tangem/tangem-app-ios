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
    var shouldAskForAccessCode: Bool { false }

    private var didReset: Bool = false

    func run(in session: CardSession, completion: @escaping CompletionResult<Bool>) {
        deleteWallets(in: session, completion: completion)
    }

    private func deleteWallets(in session: CardSession, completion: @escaping CompletionResult<Bool>) {
        guard let wallet = session.environment.card?.wallets.last else {
            deleteMasterSecret(in: session, completion: completion)
            return
        }

        PurgeWalletCommand(walletIndex: wallet.index).run(in: session) { result in
            switch result {
            case .success:
                self.didReset = true
                self.deleteWallets(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func deleteMasterSecret(in session: CardSession, completion: @escaping CompletionResult<Bool>) {
        guard session.environment.card?.masterSecret != nil else {
            resetBackup(in: session, completion: completion)
            return
        }

        PurgeMasterSecretCommand().run(in: session) { result in
            switch result {
            case .success:
                self.didReset = true
                self.resetBackup(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func resetBackup(in session: CardSession, completion: @escaping CompletionResult<Bool>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard let backupStatus = card.backupStatus,
              backupStatus != .noBackup else {
            resetAccessTokens(in: session, completion: completion)
            return
        }

        ResetBackupCommand().run(in: session) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func resetAccessTokens(in session: CardSession, completion: @escaping CompletionResult<Bool>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        guard card.firmwareVersion >= .v8 else {
            completion(.success(didReset))
            return
        }

        // Nothing to reset if backup required and backup is not done, so we can skip this step
        if card.settings.isBackupRequired {
            completion(.success(didReset))
            return
        }

        ResetAccessTokensTask().run(in: session) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
