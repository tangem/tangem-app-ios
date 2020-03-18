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
    
    init(card: CardViewModel, network: TokenNetwork = .eth, completion: @escaping (TangemKitResult<CardViewModel>) -> Void) {
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
    }

    func handleTokenBalanceLoaded(balanceValue: String) {
        guard !isCancelled else {
            return
        }
        
        card.walletTokenValue = balanceValue        

        let mainBalanceOperation = ETHCardBalanceOperation(card: card, networkUrl: TokenNetwork.eth.rawValue) { [weak self] (result) in
            switch result {
            case .success(_):
                self?.handleMainBalanceLoaded()
            case .failure(let error):
                self?.failOperationWith(error: error.0, title: error.title)
            }
        }
        operationQueue.addOperation(mainBalanceOperation)
    }
    
    func handleMainBalanceLoaded() {
        guard !isCancelled else {
            return
        }
        
        completeOperation()
    }

}
