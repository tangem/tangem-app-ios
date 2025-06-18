//
//  SolanaWalletConnectSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct SolanaWalletConnectSigner: WalletConnectSigner {
    let signer: TransactionSigner

    func sign(data: Data, using walletModel: any WalletModel) async throws -> Data {
        let pubKey = walletModel.publicKey
        return try await signer.sign(hash: data, walletPublicKey: pubKey)
            .eraseToAnyPublisher()
            .async()
    }

    func sign(hashes: [Data], using walletModel: any WalletModel) async throws -> [Data] {
        let pubKey = walletModel.publicKey

        return try await signer.sign(hashes: hashes, walletPublicKey: pubKey)
            .eraseToAnyPublisher()
            .async()
    }
}
