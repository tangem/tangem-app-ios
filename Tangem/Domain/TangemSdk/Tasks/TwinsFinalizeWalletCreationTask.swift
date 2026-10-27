//
//  TwinsFinalizeWalletCreationTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TwinsFinalizeWalletCreationTask: CardSessionRunnable {
    var shouldAskForAccessCode: Bool { false }

    private let fileToWrite: Data
    private var scanCommand: AppScanTask?

    init(fileToWrite: Data) {
        self.fileToWrite = fileToWrite
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(TangemSdkError.missingPreflightRead))
            return
        }

        guard let issuerKeys = SignerUtils.signerKeys(for: card.issuer.publicKey) else {
            completion(.failure(TangemSdkError.unknownError))
            return
        }

        let task = WriteIssuerDataTask(pairPubKey: fileToWrite, keys: issuerKeys)
        task.run(in: session) { response in
            switch response {
            case .success:
                self.readCard(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func readCard(in session: CardSession, completion: @escaping CompletionResult<AppScanTaskResponse>) {
        // Unlike the nested derivation tasks, `prepare(_:)` is deliberately not invoked here — we don't register/authenticate Twin cards
        scanCommand = AppScanTask()
        scanCommand!.run(in: session, completion: completion)
    }
}
