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
import RxSwift

public protocol WalletManager {
    var wallet: PublishSubject<Wallet> {get}
    var loadingError: PublishSubject<Error> {get}
    func update()
}

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
protocol FeeProvider {
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error>
}
