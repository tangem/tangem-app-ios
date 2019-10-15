//
//  EstimateFeeOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

class EstimateOperation: GBAsyncOperation {
    
    var completion: (TangemObjectResult<BtcFee>) -> Void
    
    private var minFee: String?
    private var normalFee: String?
    private var priorityFee: String?    
    private let operationQueue = OperationQueue()
    private var pendingRequests = 3
    private let lock = DispatchSemaphore(value: 1)
    
    init(completion: @escaping (TangemObjectResult<BtcFee>) -> Void) {
        self.completion = completion
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
        
        let operationMin: BtcRequestOperation<String> = BtcRequestOperation(endpoint: EstimateFeeEndpoint.minimal, completion: { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.minFee = value
            case .failure(_):
                break
            }
            self?.handleRequestFinish()
        })
        operationQueue.addOperation(operationMin)
        
        let operationNormal: BtcRequestOperation<String> = BtcRequestOperation(endpoint: EstimateFeeEndpoint.normal, completion: { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.normalFee = value
            case .failure(_):
                break
            }
            self?.handleRequestFinish()
        })
        operationQueue.addOperation(operationNormal)
        
        let operationPriority: BtcRequestOperation<String> = BtcRequestOperation(endpoint: EstimateFeeEndpoint.priority, completion: { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.priorityFee = value
            case .failure(_):
                break
            }
            self?.handleRequestFinish()
        })
        operationQueue.addOperation(operationPriority)
    }
    
    func completeOperation() {
        guard !isFinished && !isCancelled else {
            return
        }
        
        guard let minFee = self.minFee,
            let normalFee = self.normalFee,
            let priorityFee = self.priorityFee,
            let min = Decimal(string: minFee),
            let normal = Decimal(string: normalFee),
            let priority = Decimal(string: priorityFee) else {
                failOperationWith(error: "Fee request error")
                return
        }
        
        let fee = BtcFee(minimalKb: min, normalKb: normal, priorityKb: priority)
        completion(.success(fee))
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
