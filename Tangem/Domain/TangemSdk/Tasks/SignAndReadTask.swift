//
//  SignAndReadTask.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class SignAndReadTask: CardSessionRunnable {
    private let hashes: [Data]
    private let seedKey: Data
    private let pairWalletPublicKey: Data?
    private let hdKey: HDKey?

    private var signCommand: SignHashesCommand?

    init(hashes: [Data], seedKey: Data, pairWalletPublicKey: Data?, hdKey: HDKey?) {
        self.hashes = hashes
        self.seedKey = seedKey
        self.pairWalletPublicKey = pairWalletPublicKey
        self.hdKey = hdKey
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<SignAndReadTaskResponse>) {
        sign(in: session, key: seedKey, hdKey: hdKey) { signResult in
            switch signResult {
            case .success(let response):
                completion(.success(response))
            case .failure(TangemSdkError.walletNotFound):
                self.signWithPairWalletPublicKey(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func signWithPairWalletPublicKey(in session: CardSession, completion: @escaping CompletionResult<SignAndReadTaskResponse>) {
        guard let pairWalletPublicKey else {
            completion(.failure(TangemSdkError.walletNotFound))
            return
        }

        // We don't have derivation for `Twin` cards
        sign(in: session, key: pairWalletPublicKey, hdKey: .none, completion: completion)
    }

    private func sign(in session: CardSession, key: Data, hdKey: HDKey?, completion: @escaping CompletionResult<SignAndReadTaskResponse>) {
        signCommand = SignHashesCommand(hashes: hashes, walletPublicKey: key, derivationPath: hdKey?.derivationPath)
        signCommand!.run(in: session) { signResult in
            switch signResult {
            case .success(let signResponse):
                let publicKey = hdKey?.blockchainKey ?? key
                completion(.success(SignAndReadTaskResponse(publicKey: publicKey, signatures: signResponse.signatures, card: session.environment.card!)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension SignAndReadTask {
    struct HDKey {
        let blockchainKey: Data
        let derivationPath: DerivationPath
    }

    struct SignAndReadTaskResponse {
        let publicKey: Data
        let signatures: [Data]
        let card: Card
    }
}
