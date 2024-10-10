//
//  TransactionSignerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdkLocal

class TransactionSignerMock: TransactionSigner {
    func sign(hashes: [Data], walletPublicKey: BlockchainSdkLocal.Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        .anyFail(error: "Error")
    }

    func sign(hash: Data, walletPublicKey: BlockchainSdkLocal.Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        .anyFail(error: "Error")
    }
}
