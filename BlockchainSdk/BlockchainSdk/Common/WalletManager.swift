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
    associatedtype WalletType: Wallet
    
    var cardId: String! {get}
    var wallet: Variable<WalletType>! {get}
    var error: PublishSubject<Error> {get}
    func update()
}

extension WalletManager {
    func eraseToAnyWalletManager() -> AnyWalletManager<WalletType> {
        return AnyWalletManager<WalletType>(self)
    }
}

final public class AnyWalletManager<WalletType: Wallet>: WalletManager {
    public var cardId: String!
    public var wallet: Variable<WalletType>!
    public var error: PublishSubject<Error> = .init()
    public func update() {}
    
    private let updateBlock: () -> Void
    private let cardIdBlock: () -> String
    private let walletBlock: () -> Variable<WalletType>
    private let loadingErrorBlock: () -> PublishSubject<Error>
    
    init<WalletManagerType: WalletManager>(_ walletManager: WalletManagerType) where WalletManagerType.WalletType == WalletType {
        updateBlock = { walletManager.update() }
        cardIdBlock = { walletManager.cardId }
        walletBlock = { walletManager.wallet }
        loadingErrorBlock = { walletManager.error }
    }
}

protocol BlockchainProcessable {
    associatedtype TransactionBuilder
    associatedtype NetworkManager
    
    var txBuilder: TransactionBuilder!  {get}
    var network: NetworkManager!  {get}
}

@available(iOS 13.0, *)
protocol TransactionSizeEstimator {
    func getEstimateSize(for transaction: Transaction) -> Decimal?
}

@available(iOS 13.0, *)
public protocol TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error>
}

@available(iOS 13.0, *)
public protocol TransactionSigner {
    func sign(hashes: [Data], cardId: String, callback: @escaping (TaskEvent<SignResponse>) -> Void)
    func sign(hashes: [Data], cardId: String) -> AnyPublisher<SignResponse, Error>
}

@available(iOS 13.0, *)
public protocol FeeProvider {
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error>
}
