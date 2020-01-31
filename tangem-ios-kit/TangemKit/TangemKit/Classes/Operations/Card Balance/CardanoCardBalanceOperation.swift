//
//  BTCCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import GBAsyncOperation

class CardanoCardBalanceOperation: GBAsyncOperation {
    
    lazy var internalQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    var card: CardViewModel
    var completion: (TangemKitResult<CardViewModel>) -> Void
    
    init(card: CardViewModel, completion: @escaping (TangemKitResult<CardViewModel>) -> Void) {
        self.card = card
        self.completion = completion
        
        super.init()
    }
    
    override func main() {
        setupOperations()
    }
    
    func setupOperations()  {
        let balanceOperation = CardanoNetworkBalanceOperation(address: card.address) { (result) in
            switch result {
            case .success(let response):
                if let balanceDecimal = Decimal(string: response.balance) {
                     self.card.walletValue =  "\(balanceDecimal.rounded(blockchain: .cardano))"
                } else {
                     self.card.walletValue = response.balance
                }
                CardanoPendingTransactionsStorage.shared.cleanup(existingTransactionsIds: response.transactionList, card: self.card)
            case .failure(let error):
                self.failOperationWith(error: error)
            }
        }
        internalQueue.addOperation(balanceOperation)
        
        let unspentOutputsOperation = CardanoUnspentOutputsOperation(address: card.address) { (result) in
            switch result {
            case .success(let value):
                guard let cardanoCardEngine = self.card.cardEngine as? CardanoEngine else {
                    assertionFailure()
                    self.failOperationWith(error: "Card engine should be of CardanoEngine class")
                    return
                }
                
                cardanoCardEngine.unspentOutputs = value
            case .failure(let error):
                self.failOperationWith(error: error)
            }
        }
        internalQueue.addOperation(unspentOutputsOperation)
        
        let completionOperation = GBBlockOperation { 
            self.completeOperation()
        }
        internalQueue.addOperation(completionOperation)
    }
    
    internal func completeOperation() {
        guard !isCancelled else {
            return
        }
        
        completion(.success(card))
        finish()
    }
    
    func failOperationWith(error: Error) {
        guard !isCancelled else {
            return
        }
        
        completion(.failure(error))
        cancel()
    }
    
    override func cancel() {
        internalQueue.cancelAllOperations()
        super.cancel()
    }
    
}
