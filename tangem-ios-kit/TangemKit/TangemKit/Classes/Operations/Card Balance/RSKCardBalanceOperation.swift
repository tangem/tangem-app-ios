//
//  ETHCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class RSKCardBalanceOperation: BaseCardBalanceOperation {

     var hasToken: Bool = false
    
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }

        card.mult = priceUSD
        
        if !hasToken {
            getMainBalance()
            return
        }
        
        let tokenBalanceOperation = TokenNetworkBalanceOperation(card: card, network: .rsk) { [weak self] (result) in
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
        getMainBalance()
    }
    
    func getMainBalance() {
        let mainBalanceOperation = ETHCardBalanceOperation(card: card, networkUrl: TokenNetwork.rsk.rawValue) { [weak self] (result) in
                  switch result {
                  case .success:
                      self?.handleMainBalanceLoaded()
                  case .failure(let error):
                      self?.card.mult = 0
                      self?.failOperationWith(error: error)
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
