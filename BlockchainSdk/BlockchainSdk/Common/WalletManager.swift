//
//  Walletmanager.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

public protocol WalletManager {
    var wallet: Wallet {get}
    func update()
}

protocol TransactionBuilder {
    func getEstimateSize(for transaction: Transaction) -> Int?
}

@available(iOS 13.0, *)
protocol TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner, completion: @escaping (Result<Bool, Error>) -> Void)
}

@available(iOS 13.0, *)
protocol TransactionSigner {
    func sign(hashes: [Data], cardId: String, callback: @escaping (TaskEvent<SignResponse>) -> Void)
    func sign(hashes: [Data], cardId: String) -> AnyPublisher<SignResponse, Error>
}

protocol FeeProvider {
    func getFee(amount: Amount, source: String, destination: String, completion: @escaping (Result<[Amount], Error>) -> Void)
}
