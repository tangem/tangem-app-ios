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
    var wallet: CurrentValueSubject<Wallet, Error> {get}
    func update()
}

protocol TransactionBuilder {
    func getEstimateSize(for transaction: Transaction) -> Decimal?
}

@available(iOS 13.0, *)
protocol TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error>
}

@available(iOS 13.0, *)
protocol TransactionSigner {
    func sign(hashes: [Data], cardId: String, callback: @escaping (TaskEvent<SignResponse>) -> Void)
    func sign(hashes: [Data], cardId: String) -> AnyPublisher<SignResponse, Error>
}

protocol FeeProvider {
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error>
}
