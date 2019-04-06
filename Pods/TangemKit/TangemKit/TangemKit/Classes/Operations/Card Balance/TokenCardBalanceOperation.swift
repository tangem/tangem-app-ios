//
//  TokenCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class TokenCardBalanceOperation: BaseCardBalanceOperation {
    
    var network: TokenNetwork
    
    init(card: Card, network: TokenNetwork = .eth, completion: @escaping (TangemKitResult<Card>) -> Void) {
        self.network = network
        super.init(card: card, completion: completion)
    }

    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }

        card.mult = priceUSD

        let tokenBalanceOperation = TokenNetworkBalanceOperation(card: card, network: network) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleTokenBalanceLoaded(balanceValue: value)
            case .failure(let error):
                self?.card.mult = 0
                self?.failOperationWith(error: error)
            }
        }
        operationQueue.addOperation(tokenBalanceOperation)
        
        let mainBalanceOperation = EthereumNetworkBalanceOperation(address: card.address) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleMainBalanceLoaded(balanceValue: value)
            case .failure(let error):
                self?.card.mult = 0
                self?.failOperationWith(error: error)
            }
        }
        operationQueue.addOperation(mainBalanceOperation)
    }

    func handleTokenBalanceLoaded(balanceValue: String) {
        guard !isCancelled else {
            return
        }
        
        card.walletTokenValue = balanceValue        

        completeOperation()
    }
    
    func handleMainBalanceLoaded(balanceValue: String) {
        guard !isCancelled else {
            return
        }
        
        card.walletValue = balanceValue
        
        completeOperation()
    }

}
