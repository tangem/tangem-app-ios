//
//  SignAndReadTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class SignAndReadTask: CardSessionRunnable {
    let hashes: [Data]
    let walletPublicKey: Data
    let pairWalletPublicKey: Data?
    let derivationPath: DerivationPath?
    private var signCommand: SignHashesCommand? = nil

    init(hashes: [Data], walletPublicKey: Data, pairWalletPublicKey: Data?, derivationPath: DerivationPath?) {
        self.hashes = hashes
        self.walletPublicKey = walletPublicKey
        self.pairWalletPublicKey = pairWalletPublicKey
        self.derivationPath = derivationPath
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<SignAndReadTaskResponse>) {
        sign(in: session, key: walletPublicKey) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                if let pairWalletPublicKey = self.pairWalletPublicKey,
                   case TangemSdkError.walletNotFound = error {
                    self.sign(in: session, key: pairWalletPublicKey, completion: completion)
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    private func sign(in session: CardSession, key: Data, completion: @escaping CompletionResult<SignAndReadTaskResponse>) {
        signCommand = SignHashesCommand(hashes: hashes, walletPublicKey: key, derivationPath: derivationPath)
        signCommand!.run(in: session) { signResult in
            switch signResult {
            case .success(let signResponse):
                completion(.success(SignAndReadTaskResponse(signatures: signResponse.signatures, card: session.environment.card!)))
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
