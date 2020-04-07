//
//  BTCFeeOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

import SwiftyJSON
import GBAsyncOperation
import Alamofire

class BtcFeeOperation: GBAsyncOperation {
    
    var completion: (TangemObjectResult<BtcFee>) -> Void
    
    private let operationQueue = OperationQueue()
    private unowned let engine: BTCEngine
    private var retryCount = 1
    
    init(with engine: BTCEngine, completion: @escaping (TangemObjectResult<BtcFee>) -> Void) {
        self.completion = completion
        self.engine = engine
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
                    return getEstimateFeeRequest()
                }
            }
        }()
        
        operationQueue.addOperation(operation)
    }
    
    func getEstimateFeeRequest() -> GBAsyncOperation {
        let feeRequestOperation: EstimateOperation =
            EstimateOperation {[weak self] result in
                switch result {
                case .success(let fee):
                    self?.completeOperation(fee)
                case .failure(let error):
                    self?.failOperation(with: error)
                }
        }
        return feeRequestOperation
    }
    
    func getBlockcypherRequest() -> GBAsyncOperation {
        let feeRequestOperation: BtcRequestOperation<BlockcypherFeeResponse> =
            BtcRequestOperation(endpoint: BlockcypherEndpoint.fee(api: .btc)) {[weak self] result in
                switch result {
                case .success(let feeResponse):
                    guard let minKb = feeResponse.low_fee_per_kb,
                        let normalKb = feeResponse.medium_fee_per_kb,
                        let maxKb = feeResponse.high_fee_per_kb else {
                            self?.failOperation(with: "Can't load fee")
                            return
                    }
                    
                    let minKbValue = Decimal(minKb).satoshiToBtc
                    let normalKbValue = Decimal(normalKb).satoshiToBtc
                    let maxKbValue = Decimal(maxKb).satoshiToBtc
                    let fee = BtcFee(minimalKb: minKbValue, normalKb: normalKbValue, priorityKb: maxKbValue)
                    self?.completeOperation(fee)
                case .failure(let error):
                    self?.failOperation(with: error)
                }
        }
        feeRequestOperation.useTestNet =  engine.card.isTestBlockchain
        
        return feeRequestOperation
    }
    
    
    
    func completeOperation(_ fee: BtcFee) {
        guard !isFinished && !isCancelled else {
            return
        }
        completion(.success(fee))
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

