//
//  BlockchainInfoBalanceOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

class BlockchainInfoBalanceOperation: GBAsyncOperation {
    
    var completion: (TangemObjectResult<BtcResponse>) -> Void
    
    private var address: BlockchainInfoAddressResponse?
    private var unspent: BlockchainInfoUnspentResponse?
    private let walletAddress: String
   
    private let operationQueue = OperationQueue()
    private var pendingRequests = 2
    private let lock = DispatchSemaphore(value: 1)
    
    init(walletAddress: String, completion: @escaping (TangemObjectResult<BtcResponse>) -> Void) {
        self.completion = completion
        self.walletAddress = walletAddress
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
    
    override func main() {
        guard !isCancelled else {
            return
        }
        
        let operationAddress: BtcRequestOperation<BlockchainInfoAddressResponse> = BtcRequestOperation(endpoint: BlockchainInfoEndpoint.address(address: walletAddress), completion: { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.address = value
                self?.handleRequestFinish()
            case .failure(let error):
                self?.failOperationWith(error: error)
            }
        })
        operationQueue.addOperation(operationAddress)
        
        let operationUnspent: BtcRequestOperation<BlockchainInfoUnspentResponse> = BtcRequestOperation(endpoint: BlockchainInfoEndpoint.unspents(address: walletAddress), completion: { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.unspent = value
                self?.handleRequestFinish()
            case .failure(let error):
                if (error as? String)?.contains("No free outputs to spend") ?? false {
                        self?.unspent = BlockchainInfoUnspentResponse(unspent_outputs: [])
                        self?.handleRequestFinish()
                } else {
                    self?.failOperationWith(error: error)
                }
            }
            
        })
        operationQueue.addOperation(operationUnspent)
    }
    
    func completeOperation() {
        guard !isFinished && !isCancelled else {
            return
        }

        guard let balance = self.address?.final_balance,
            let txs = self.address?.txs else {
                failOperationWith(error: Localizations.loadedWalletErrorObtainingBlockchainData)
                return
        }
        
        let utxs: [BtcTx] = self.unspent?.unspent_outputs?.compactMap { utxo -> BtcTx?  in
            guard let hash = utxo.tx_hash_big_endian,
                let n = utxo.tx_output_n,
                let val = utxo.value else {
                    return nil
            }
            
            let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: val)
            return btx
        } ?? []
        
        let satoshiBalance = Decimal(balance).satoshiToBtc
        let hasUnconfirmed = txs.first(where: {$0.block_height == nil}) != nil
        let unconfirmedBalance = hasUnconfirmed ? 1 : 0
        let response = BtcResponse(balance: satoshiBalance, unconfirmed_balance: unconfirmedBalance, txrefs: utxs)
    
        completion(.success(response))
        finish()
    }
    
    func failOperationWith(error: Error) {
        guard !isFinished && !isCancelled else {
            return
        }
        
        completion(.failure(error))
        finish()
    }
    
    func handleRequestFinish() {
        removeRequest()
        if !hasRequests {
            completeOperation()
        }
    }
}
