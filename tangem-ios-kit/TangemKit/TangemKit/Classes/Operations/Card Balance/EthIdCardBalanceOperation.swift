//
//  ETHCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import GBAsyncOperation

class ETHIdCardBalanceOperation: BaseCardBalanceOperation {
    
    private var pendingRequests = 0
    private let lock = DispatchSemaphore(value: 1)
    private var pendingTxCountLoaded = -1
    private var txHashes: [String] = []
    private var currentRequest: Int = -1
    private var hasApprovalTx: Bool = false
    var networkUrl: String
    
    init(card: CardViewModel, networkUrl: String, completion: @escaping (TangemKitResult<CardViewModel>) -> Void) {
        self.networkUrl = networkUrl
        super.init(card: card, completion: completion)
    }
    
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }
        
        card.mult = priceUSD
//        let approvalAddress = (card.cardEngine as! ETHIdEngine).approvalAddress!
//
//        let pendingApprovalTxCountOperation = EthereumNetworkPendingTxCountOperation(address: approvalAddress, networkUrl: networkUrl) { [weak self] (result) in
//            switch result {
//            case .success(let value):
//                self?.handlePendingTxCountLoaded(txCount: value)
//            case .failure(let error):
//                self?.failOperationWith(error: error)
//            }
//
//        }
//        addRequest()
//        operationQueue.addOperation(pendingApprovalTxCountOperation)
        
        performAddressRequest()
    }
    
    
    func performAddressRequest() {
        guard !card.address.isEmpty else {
            return
        }
        
        let operation: BtcRequestOperation<BlockcypherAddressResponse> = BtcRequestOperation(endpoint: BlockcypherEndpoint.address(address: card.address, api: .eth), completion: { [weak self] (result) in
            switch result {
            case .success(let response):
                guard let txs = response.txrefs else {
                  self?.handleAddressRequest([])
                return
                }
                self?.handleAddressRequest(txs)
            case .failure(let error):
                self?.failOperationWith(error: error)
            }
        })
        
        operation.useTestNet = false
        addRequest()
        operationQueue.addOperation(operation)
    }
    
    func performTxsRequest() {
        guard txHashes.count > 0, currentRequest < txHashes.count - 1 else {
            handleTxsComplete(hasTrusted: false)
            return
        }
        
        currentRequest += 1
        let txHash = txHashes[currentRequest]
        
        let operation: BtcRequestOperation<BlockcypherTx> = BtcRequestOperation(endpoint: BlockcypherEndpoint.txs(txHash: txHash, api: .eth), completion: { [weak self] (result) in
            switch result {
            case .success(let response):
                guard let addresses = response.addresses else {
                    self?.failOperationWith(error: "Failed to get data from blockchain")
                    return
                }
                
                guard let approvalAddress = (self?.card.cardEngine as? ETHIdEngine)?.approvalAddress.stripHexPrefix() else {
                    return
                }
                
                if addresses.contains(approvalAddress) {
                    self?.handleTxsComplete(hasTrusted: true)
                    return
                }
                
                self?.performTxsRequest()
            case .failure(let error):
                self?.failOperationWith(error: error)
            }
        })
        
        operation.useTestNet = false
        addRequest()
        operationQueue.addOperation(operation)
    }
    
    
    func handleAddressRequest(_ txrefs: [BlockcypherTxref]) {
         removeRequest()
        self.txHashes = txrefs.compactMap { $0.tx_hash }
        self.currentRequest = -1
        performTxsRequest()
    }
    
    func handleTxsComplete(hasTrusted: Bool) {
        hasApprovalTx = hasTrusted
        removeRequest()
        if !hasRequests {
            complete()
        }
    }
    
    func handlePendingTxCountLoaded(txCount: Int) {
        guard !isCancelled else {
            removeRequest()
            return
        }
        pendingTxCountLoaded = txCount
        
        removeRequest()
        if !hasRequests {
            complete()
        }
    }
    
    func complete() {
       // (card.cardEngine as! ETHIdEngine).approvalTxCount = pendingTxCountLoaded
        (card.cardEngine as? ETHIdEngine)!.hasApprovalTx = hasApprovalTx
        completeOperation()
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
        return pendingRequests > 0
    }
}
