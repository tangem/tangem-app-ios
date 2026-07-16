//
//  SolanaTransactionSigner.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SolanaSwift

class SolanaTransactionSigner: Signer {
    var publicKey: PublicKey {
        PublicKey(data: walletPublicKey.blockchainKey)!
    }

    let transactionSigner: TransactionSigner
    let walletPublicKey: Wallet.PublicKey

    init(transactionSigner: TransactionSigner, walletPublicKey: Wallet.PublicKey) {
        self.transactionSigner = transactionSigner
        self.walletPublicKey = walletPublicKey
    }

    func sign(message: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        // Backed by the async variant: no stored subscription to accumulate or leak
        Task {
            do {
                let data = try await sign(message: message)
                completion(.success(data))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func sign(message: Data) async throws -> Data {
        try await transactionSigner.sign(hash: message, walletPublicKey: walletPublicKey).async()
    }
}
