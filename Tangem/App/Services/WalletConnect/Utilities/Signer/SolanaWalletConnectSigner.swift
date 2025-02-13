//
//  SolanaWalletConnectSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SolanaWalletConnectSigner: WalletConnectSigner {
    let signer: TangemSigner

    func sign(data: Data, using walletModel: WalletModel) async throws -> Data {
        let pubKey = walletModel.wallet.publicKey
        return try await signer.sign(hash: data, walletPublicKey: pubKey)
            .eraseToAnyPublisher()
            .async()
    }

    func sign(hashes: [Data], using walletModel: WalletModel) async throws -> [Data] {
        let pubKey = walletModel.wallet.publicKey

        return try await signer.sign(hashes: hashes, walletPublicKey: pubKey)
            .eraseToAnyPublisher()
            .async()
    }
}
