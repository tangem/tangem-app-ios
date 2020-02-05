//
//  BtcBalanceOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation
import Alamofire

class BtcBalanceOperation: GBAsyncOperation {
    
    var completion: (TangemObjectResult<BtcResponse>) -> Void
    
    private let operationQueue = OperationQueue()
    private unowned let engine: BTCEngine
    private var retryCount = 1
    private let blockcyperApi: BlockcyperApi
    
    init(with engine: BTCEngine, blockcyperApi: BlockcyperApi, completion: @escaping (TangemObjectResult<BtcResponse>) -> Void) {
        self.completion = completion
        self.engine = engine
        self.blockcyperApi = blockcyperApi
    }
    
    override func main() {
        startOperation()
    }
    
    private func startOperation() {
        guard !isCancelled else {
            return
        }
        
        let operation: GBAsyncOperation = {
            if engine.card.isTestBlockchain {
                return getBlockcypherRequest()
            } else {
                switch engine.currentBackend {
                case .blockcypher:
                    return getBlockcypherRequest()
                case .blockchainInfo:
                    return getBlockchainInfoRequest()
                }
            }
        }()
        
        operationQueue.addOperation(operation)
    }
    
    func getBlockchainInfoRequest() -> GBAsyncOperation {
        let balanceRequestOperation: BlockchainInfoBalanceOperation =
            BlockchainInfoBalanceOperation(walletAddress: engine.card.address) {[weak self] result in
                switch result {
                case .success(let response):
                    self?.completeOperation(response)
                case .failure(let error):
                    self?.failOperation(with: error)
                }
        }
        return balanceRequestOperation
    }
    
    func getBlockcypherRequest() -> GBAsyncOperation {
        let operation: BtcRequestOperation<BlockcypherAddressResponse> = BtcRequestOperation(endpoint: BlockcypherEndpoint.address(address: engine.card.address, api: blockcyperApi), completion: { [weak self] (result) in
            switch result {
            case .success(let response):
                guard let balance = response.balance,
                    let uncBalance = response.unconfirmed_balance
                    else {
                        self?.failOperation(with: BTCCardBalanceError.balanceIsNil)
                        return
                }
                
                let satoshiBalance = Decimal(balance).satoshiToBtc
                let txs: [BtcTx] = response.txrefs?.compactMap { utxo -> BtcTx?  in
                    guard let hash = utxo.tx_hash,
                        let n = utxo.tx_output_n,
                        let val = utxo.value else {
                            return nil
                    }
                    
                    let btx = BtcTx(tx_hash: hash, tx_output_n: n, value: UInt64(val))
                    return btx
                } ?? []
                
                let btcResponse = BtcResponse(balance: satoshiBalance, unconfirmed_balance: uncBalance, txrefs: txs)
                
                self?.completeOperation(btcResponse)
            case .failure(let error):
                self?.failOperation(with: error)
            }
        })
        
        operation.useTestNet = engine.card.isTestBlockchain
        return operation
    }
    
    
    
    func completeOperation(_ response: BtcResponse) {
        guard !isFinished && !isCancelled else {
            return
        }
        completion(.success(response))
        finish()
    }
    
    func failOperation(with error: Error) {
        guard !isFinished && !isCancelled else {
            return
        }
        let reachable = NetworkReachabilityManager.init()?.isReachable ?? false
        if retryCount > 0 && reachable {
            retryCount -= 1
            engine.switchBackend()
            startOperation()
            return
        }
        
        completion(.failure(error))
        finish()
    }
}

