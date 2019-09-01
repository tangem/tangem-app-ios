//
//  ETHCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class ETHCardBalanceOperation: BaseCardBalanceOperation {

    private var pendingRequests = 0
    private let lock = DispatchSemaphore(value: 1)

    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }

        card.mult = priceUSD

        let txCountOperation = EthereumNetworkTxCountOperation(address: card.address) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleTxCountLoaded(txCount: value)
            case .failure(let error):
                self?.cancel()
                self?.failOperationWith(error: error)
            }
            
        }
        addRequest()
        operationQueue.addOperation(txCountOperation)
        
        let pendingTxCountOperation = EthereumNetworkPendingTxCountOperation(address: card.address) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handlePendingTxCountLoaded(txCount: value)
            case .failure(let error):
                self?.cancel()
                self?.failOperationWith(error: error)
            }
            
        }
        addRequest()
        operationQueue.addOperation(pendingTxCountOperation)
        
        
        let operation = EthereumNetworkBalanceOperation(address: card.address) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleBalanceLoaded(balanceValue: value)
            case .failure(let error):
                self?.cancel()
                self?.card.mult = 0
                self?.failOperationWith(error: error)
            }
        }
        addRequest()
        operationQueue.addOperation(operation)
    }

    func handleBalanceLoaded(balanceValue: String) {
        guard !isCancelled else {
            removeRequest()
            return
        }
        
        card.walletValue = balanceValue
        removeRequest()
        if !hasRequests {
             completeOperation()
        }
    }
    
    func handleTxCountLoaded(txCount: Int) {
        guard !isCancelled else {
          removeRequest()
            return
        }
        
        (card.cardEngine as! ETHEngine).txCount = txCount
        removeRequest()
        if !hasRequests {
            completeOperation()
        }
    }
    
    func handlePendingTxCountLoaded(txCount: Int) {
        guard !isCancelled else {
           removeRequest()
            return
        }
        
        (card.cardEngine as! ETHEngine).pendingTxCount = txCount
        removeRequest()
        if !hasRequests {
            completeOperation()
        }
    }
    
    func addRequest() {
        lock.wait()
        defer { lock.signal() }
        pendingRequests += 1
    }
    
    func removeRequest() {
        lock.wait()
        defer { lock.signal() }
        pendingRequests -= 1
    }
    
    var hasRequests: Bool {
        lock.wait()
        defer { lock.signal() }
        return pendingRequests != 0
    }
}
