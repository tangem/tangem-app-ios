//
//  BtcSendOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

class BtcSendOperation: GBAsyncOperation {
    
    var completion: (TangemObjectResult<Bool>) -> Void
    
    private let operationQueue = OperationQueue()
    private unowned let engine: BTCEngine
    private let tx: String
    private var retryCount = 1
    private let blockcyperApi: BlockcyperApi
    
    init(with engine: BTCEngine, blockcyperApi: BlockcyperApi, txHex: String, completion: @escaping (TangemObjectResult<Bool>) -> Void) {
        self.completion = completion
        self.engine = engine
        self.tx = txHex
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
                    return getBlockchainInfo()
                }
            }
        }()
        
        operationQueue.addOperation(operation)
    }
    
    func getBlockchainInfo() -> GBAsyncOperation {
        let sendOp: BtcRequestOperation<String> = BtcRequestOperation(endpoint: BlockchainInfoEndpoint.send(txHex: tx)) {[weak self] result in
            switch result {
            case .success(let sendResponse):
                if sendResponse == "Transaction Submitted" {
                    self?.engine.unconfirmedBalance = nil
                    self?.completeOperation()
                } else {
                    self?.failOperation(with: "Empty response")
                }
            case .failure(let error):
                print(error)
                self?.failOperation(with: error)
            }
        }
        return sendOp
    }
    
    func getBlockcypherRequest() -> GBAsyncOperation {
        let sendOp: BtcRequestOperation<String> = BtcRequestOperation(endpoint: BlockcypherEndpoint.send(txHex: tx, api: blockcyperApi)) {[weak self] result in
            switch result {
            case .success(let sendResponse):
                if !sendResponse.isEmpty {
                    self?.engine.unconfirmedBalance = nil
                    self?.completeOperation()
                } else {
                    self?.failOperation(with: "Empty response")
                }
            case .failure(let error):
                print(error)
                self?.failOperation(with: error)
            }
        }
        sendOp.useTestNet =  engine.card.isTestBlockchain
        return sendOp
    }
    
    
    
    func completeOperation() {
        guard !isFinished && !isCancelled else {
            return
        }
        completion(.success(true))
        finish()
    }
    
    func failOperation(with error: Error) {
        guard !isFinished && !isCancelled else {
            return
        }
        
//        if retryCount > 0 {
//            retryCount -= 1
//            engine.switchBackend()
//            startOperation()
//            return
//        }
        
        completion(.failure(error))
        finish()
    }
}

