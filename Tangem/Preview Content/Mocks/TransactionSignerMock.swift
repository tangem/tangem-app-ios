//
//  TransactionSignerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemSdk

class TransactionSignerMock: TransactionSigner {
    func sign(hashes: [Data], walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<[Data], any Error> {
        .anyFail(error: "Error")
    }

    func sign(hash: Data, walletPublicKeys: [BlockchainSdk.Wallet.PublicKey]) -> AnyPublisher<[Data], any Error> {
        .anyFail(error: "Error")
    }

    func sign(hashes: [Data], walletPublicKeys: [BlockchainSdk.Wallet.PublicKey]) -> AnyPublisher<[Data], Error> {
        .anyFail(error: "Error")
    }

    func sign(hash: Data, walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        .anyFail(error: "Error")
    }

    func sign(dataToSign: [SignData], seedKey: Data) -> AnyPublisher<[(signature: Data, publicKey: Data)], Error> {
        .anyFail(error: "Error")
    }
}
