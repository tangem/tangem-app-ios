//
//  XlmCardBalanceOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import stellarsdk

class XlmCardBalanceOperation: BaseCardBalanceOperation {
    private var pendingRequests = 2
    private let lock = DispatchSemaphore(value: 1)
    
    private var balance: String?
    private var sequence: Int64?
    private var baseReserveStroops: Int?
    private var baseFeeStroops: Int?
    
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }
        
        card.mult = priceUSD
        
        let stellarSdk = (card.cardEngine as! XlmEngine).stellarSdk
        stellarSdk.accounts.getAccountDetails(accountId: card.address) {[weak self] response -> (Void) in
            switch response {
            case .success(let accountResponse):
                guard let xlmBalance = accountResponse.balances.first(where: {$0.assetType == AssetTypeAsString.NATIVE}) else {
                    self?.card.mult = 0
                    self?.failOperationWith(error: "Empty balance")
                    return
                }
                self?.balance = xlmBalance.balance
                self?.sequence = accountResponse.sequenceNumber
                self?.handleRequestComplete()
            case .failure(let horizonRequestError):
                self?.card.mult = 0
                self?.failOperationWith(error: horizonRequestError)
            }
        }
        
        stellarSdk.ledgers.getLedgers(cursor: nil, order: Order.descending, limit: 1, response: { [weak self] response -> (Void) in
            switch response {
            case .success(let page):
                guard let lastLedger = page.records.first else {
                    self?.failOperationWith(error: "Couldn't find latest ledger")
                    return
                }
                self?.baseReserveStroops = lastLedger.baseReserveInStroops
                self?.baseFeeStroops = lastLedger.baseFeeInStroops
                self?.handleRequestComplete()
            case .failure(let horizonRequestError):
                self?.failOperationWith(error: horizonRequestError)
                break
            }
            
        })
        
        
    }
    
    func complete() {
        
        let engine = card.cardEngine as! XlmEngine
        
        guard let baseFeeS = self.baseFeeStroops,
            let baseReserveS = self.baseReserveStroops,
            let balance = self.balance,
            let decimalBalance = Decimal(string: balance),
            let sequence = self.sequence else {
                card.mult = 0
                failOperationWith(error: "Response error")
                return
        }
        
       
        engine.sequence = sequence
        
        let divider =  Decimal(10000000)
        let baseFee = Decimal(baseFeeS)/divider
        let baseReserve = Decimal(baseReserveS)/divider
        let fullReserve = baseReserve * Decimal(2.0)
        let balanceWithoutReserve = decimalBalance - fullReserve
        engine.baseReserve = baseReserve
        engine.baseFee = baseFee
        card.walletValue = "\(balanceWithoutReserve)"
        engine.walletReserve = "\(fullReserve)"
        completeOperation()
    }
    
    func handleRequestComplete() {
        guard !isCancelled else {
            return
        }
        removeRequest()
        if !hasRequests {
            complete()
        }
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
