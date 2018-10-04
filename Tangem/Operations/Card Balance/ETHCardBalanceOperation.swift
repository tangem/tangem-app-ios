//
//  ETHCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class ETHCardBalanceOperation: AsynchronousOperation {
    
    let balanceFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.maximumFractionDigits = 8
        numberFormatter.minimumFractionDigits = 2
        return numberFormatter
    }()
    
    var card: Card
    var completion: (Result<Card>) -> Void
    
    let operationQueue = OperationQueue()
    
    init(card: Card, completion: @escaping (Result<Card>) -> Void) {
        self.card = card
        self.completion = completion
        
        operationQueue.maxConcurrentOperationCount = 1
    }
    
    override func main() {
        let coinMarketOperation = CoinMarketOperation(network: CoinMarketNetwork.btc) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleMarketInfoLoaded(priceUSD: value)
            case .failure(let error):
                self?.failOperationWith(error: String(describing: error))
            }
            
        }
        operationQueue.addOperation(coinMarketOperation)
    }
    
    func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }
        
        card.mult = priceUSD
        
        let operation = EthereumNetworkBalanceOperation(address: card.ethAddress, isTestNet: card.isTestNet) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleBalanceLoaded(balanceValue: value)
            case .failure(let error):
                self?.card.mult = 0
                self?.failOperationWith(error: error)
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func handleBalanceLoaded(balanceValue: UInt64) {
        guard !isCancelled else {
            return
        }
        
        card.valueUInt64 = balanceValue
        
        let wei = Double(card.valueUInt64)
        let walletValue = wei / 1000000000000000000.0
        card.walletValue = self.balanceFormatter.string(from: NSNumber(value: walletValue))!
        
        let usdWalletValue = walletValue * card.mult
        card.usdWalletValue = self.balanceFormatter.string(from: NSNumber(value: usdWalletValue))!
        
        completeOperation()
    }
    
    override func cancel() {
        super.cancel()
        operationQueue.cancelAllOperations()
    }
    
    func completeOperation() {
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
        finish()
    }
    
}
