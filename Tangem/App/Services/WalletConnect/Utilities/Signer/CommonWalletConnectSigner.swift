//
//  CommonWalletConnectSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CommonWalletConnectSigner: WalletConnectSigner {
    let signer: TangemSigner

    func sign(data: Data, using walletModel: WalletModel) async throws -> Data {
        let pubKey = walletModel.wallet.publicKey
        return try await signer.sign(hash: data, walletPublicKey: pubKey)
            .tryMap { response -> Data in
                if let unmarshalledSig = try? Secp256k1Signature(with: response).unmarshal(
                    with: pubKey.blockchainKey,
                    hash: data
                ) {
                    return unmarshalledSig.data
                } else {
                    throw WalletConnectServiceError.signFailed
                }
            }
            .eraseToAnyPublisher()
            .async()
    }

    func sign(hashes: [Data], using walletModel: WalletModel) async throws -> [Data] {
        let pubKey = walletModel.wallet.publicKey
        return try await signer.sign(hashes: hashes, walletPublicKey: pubKey)
            .tryMap { responses -> [Data] in
                try responses.enumerated().map { index, signedHash in
                    if let unmarshalledSig = try? Secp256k1Signature(with: signedHash).unmarshal(
                        with: pubKey.blockchainKey,
                        hash: hashes[index]
                    ) {
                        return unmarshalledSig.data
                    } else {
                        throw WalletConnectServiceError.signFailed
                    }
                }
            }
            .eraseToAnyPublisher()
            .async()
    }
}
