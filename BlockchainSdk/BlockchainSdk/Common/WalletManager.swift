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

public class WalletManager<TWallet: Wallet> {
    public var cardId: String!
    public var wallet: TWallet!
    public var onWallet: PublishSubject<TWallet> = .init()
    public var onError: PublishSubject<Error> = .init()
    
    var requestDisposable: Disposable?
    
    public func update() {}
    
    func walletDidUpdate() {
        onWallet.onNext(wallet)
    }
}

@available(iOS 13.0, *)
public protocol TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error>
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error>
}

@available(iOS 13.0, *)
public protocol TransactionSigner {
    func sign(hashes: [Data], cardId: String) -> AnyPublisher<SignResponse, Error>
}
