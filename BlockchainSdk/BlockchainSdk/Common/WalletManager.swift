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

public class WalletManager {
    public let cardId: String
    public var wallet: Wallet
    
    var requestDisposable: Disposable? = nil
    
    init(cardId: String, wallet: Wallet) {
        self.cardId = cardId
        self.wallet = wallet
    }
    
    public func update(completion: @escaping (Result<Wallet, Error>)-> Void) {
        fatalError("You should override this method")
    }
    
    public func createTransaction(amount: Amount, fee: Amount, destinationAddress: String) -> Result<Transaction,TransactionError> {
        let transaction = Transaction(amount: amount,
                                      fee: fee,
                                      sourceAddress: wallet.address,
                                      destinationAddress: destinationAddress,
                                      contractAddress: wallet.token?.contractAddress,
                                      date: Date(),
                                      status: .unconfirmed,
                                      hash: nil)
        
        let validationResult = validateTransaction(amount: amount, fee: fee)
        if validationResult.isEmpty {
            return .success(transaction)
        } else {
            return .failure(validationResult)
        }
    }
    
    func validateTransaction(amount: Amount, fee: Amount?) -> TransactionError {
        var errors: TransactionError = []
        
        if !validate(amount: amount) {
            errors.insert(.wrongAmount)
        }
        
        guard let fee = fee else {
            return errors
        }
        
        if !validate(amount: fee) {
            errors.insert(.wrongFee)
        }
        
        if amount.type == fee.type,
            !validate(amount: Amount(with: amount, value: amount.value + fee.value)) {
            errors.insert(.wrongTotal)
        }
        
        return errors
    }
    
    func validate(amount: Amount) -> Bool {
        guard amount.value > 0,
            let total = wallet.amounts[amount.type]?.value, total >= amount.value else {
                return false
        }
        
        return true
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



