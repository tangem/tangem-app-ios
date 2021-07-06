//
//  SignAndReadTask.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class SignAndReadTask: CardSessionRunnable {
    let hashes: [Data]
    let walletPublicKey: Data
    
    init(hashes: [Data], walletPublicKey: Data) {
        self.hashes = hashes
        self.walletPublicKey = walletPublicKey
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<SignAndReadTaskResponse>) {
        let signCommand = SignHashesCommand(hashes: hashes, walletPublicKey: walletPublicKey)
        signCommand.run(in: session) { signResult in
            switch signResult {
            case .success(let response):
                self.scanCard(session: session, signResponse: response, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func scanCard(session: CardSession, signResponse: SignHashesResponse, completion: @escaping CompletionResult<SignAndReadTaskResponse>) {
        let scanTask = PreflightReadTask(readMode: .fullCardRead, cardId: nil)
        scanTask.run(in: session) { result in
            switch result {
            case .success(let card):
                completion(.success(SignAndReadTaskResponse(signatures: signResponse.signatures, card: card)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension SignAndReadTask {
    struct SignAndReadTaskResponse {
        let signatures: [Data]
        let card: Card
    }
}
