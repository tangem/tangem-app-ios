//
//  TransactionSignerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemSdk

class TransactionSignerMock: TransactionSigner {
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, any Error> {
        .anyFail(error: "Error")
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        .anyFail(error: "Error")
    }

    func sign(dataToSign: [SignData], seedKey: Data) -> AnyPublisher<[(signature: Data, publicKey: Data)], Error> {
        .anyFail(error: "Error")
    }
}
