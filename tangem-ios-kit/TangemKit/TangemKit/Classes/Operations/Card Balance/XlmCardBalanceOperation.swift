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
    private var pendingRequests = 3
    private let lock = DispatchSemaphore(value: 1)
    
    private var balance: String?
    private var assetBalance: String?
    private var assetCode: String?
    private var sequence: Int64?
    private var baseReserveStroops: Int?
    private var baseFeeStroops: Int?
    private var hasOutgoingTx: Bool?
    private var hasIncomingTx: Bool?
    private var operations: [OperationResponse] = []
    
    private let trustedDestination = "GAYPZMHFZERB42ONEJ4CY6ADDVTINEXMY6OZ5G6CLR4HHVKOSNJSZGMM"
    private let trustedSource = "GAZY7H4BWWEVB6QGB4RV3LW7DH5NO5CD5O6JCEQXA7N2UCGZSAPJFYW2"
    private let paymentsLimit = 200
    private let isAsset: Bool
    
    init(card: CardViewModel, isAsset: Bool, completion: @escaping (TangemKitResult<CardViewModel>) -> Void) {
        self.isAsset = isAsset
        super.init(card: card, completion: completion)
    }
    
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }
        
        card.mult = priceUSD
        
        let stellarSdk = (card.cardEngine as! XlmEngine).stellarSdk
        stellarSdk.accounts.getAccountDetails(accountId: card.address) {[weak self] response -> (Void) in
            switch response {
            case .success(let accountResponse):
                if let xlmBalance = accountResponse.balances.first(where: {$0.assetType == AssetTypeAsString.NATIVE}) {
                    self?.balance = xlmBalance.balance
                }
                
                if let xlmAssetBalance = accountResponse.balances.first(where: {$0.assetType != AssetTypeAsString.NATIVE}) {
                    self?.assetBalance = xlmAssetBalance.balance
                    self?.assetCode = xlmAssetBalance.assetCode
                }
                
                self?.sequence = accountResponse.sequenceNumber
                self?.handleRequestComplete()
            case .failure(let horizonRequestError):
                self?.card.mult = 0
                self?.failOperationWith(error: horizonRequestError)
            }
        }
        
        stellarSdk.ledgers.getLedgers(cursor: nil, order: stellarsdk.Order.descending, limit: 1, response: { [weak self] response -> (Void) in
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
            }
            
        })
        
        requestPayments()
    }
    
    func requestPayments() {
        let stellarSdk = (card.cardEngine as! XlmEngine).stellarSdk
        stellarSdk.payments.getPayments(forAccount: card.address, from: nil, order: Order.descending, limit: paymentsLimit, includeFailed: false, join: nil) { [weak self]  response -> (Void) in
            switch response {
            case .success(let page):
                self?.operations.append(contentsOf: page.records)
                self?.requestAllPaymentPages(page)
            case .failure(let horizonRequestError):
                 self?.failOperationWith(error: horizonRequestError)
            }
        }
    }
    
    func requestAllPaymentPages(_ page: PageResponse<OperationResponse>) {
        if page.records.count == paymentsLimit  {
            page.getNextPage {[weak self] nextPageResponse -> (Void) in
                switch nextPageResponse {
                case .success(let nextPage):
                      self?.operations.append(contentsOf: nextPage.records)
                      self?.requestAllPaymentPages(nextPage)
                case .failure(let horizonRequestError):
                    self?.failOperationWith(error: horizonRequestError)
                }
            }
        } else {
            parsePayments()
        }
    }
    
    func parsePayments() {
        hasIncomingTx = operations.first(where: { operationResponse -> Bool in
            if let paymentResponse = operationResponse as? PaymentOperationResponse {
                return paymentResponse.from == trustedSource
            }
            return false
        }) != nil
        
        hasOutgoingTx = operations.first(where: { operationResponse -> Bool in
                  if let paymentResponse = operationResponse as? PaymentOperationResponse {
                      return paymentResponse.to == trustedDestination
                  }
                  return false
              }) != nil
        
         
        handleRequestComplete()
    }
    
    func complete() {
        
        let engine = card.cardEngine as! XlmEngine
        
        guard let baseFeeS = self.baseFeeStroops,
            let baseReserveS = self.baseReserveStroops,
            let balance = self.balance,
            let decimalBalance = Decimal(string: balance),
            let sequence = self.sequence,
            let incoming = self.hasIncomingTx,
            let outgoing = self.hasOutgoingTx else {
                card.mult = 0
                failOperationWith(error: "Response error")
                return
        }
        
        engine.sequence = sequence
        
        let divider =  Decimal(10000000)
        let baseFee = Decimal(baseFeeS)/divider
        let baseReserve = Decimal(baseReserveS)/divider
        let reserveMultiply = isAsset ? 3.0 : 2.0
        let fullReserve = baseReserve * Decimal(reserveMultiply)
        
        if let assetBalance = self.assetBalance,
            let decimalAssetBalance = Decimal(string: assetBalance) {
            engine.assetBalance = decimalAssetBalance
            engine.assetCode = self.assetCode
            card.walletTokenValue = decimalAssetBalance > 0 ? "\(decimalAssetBalance)" : "0"
            let balanceWithoutReserve = decimalBalance - fullReserve
            card.walletValue = "\(balanceWithoutReserve)"
            engine.walletReserve = "\(fullReserve)"
        } else {
            let balanceWithoutReserve = decimalBalance - fullReserve
            card.walletValue = "\(balanceWithoutReserve)"
            engine.walletReserve = "\(fullReserve)"
        }
        
        
        engine.hasIncomingTrustedTx = incoming
        engine.hasOutgoingTrustedTx = outgoing
        engine.baseReserve = baseReserve
        engine.baseFee = baseFee
        
        
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
