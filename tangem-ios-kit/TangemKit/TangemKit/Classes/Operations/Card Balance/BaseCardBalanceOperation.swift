//
//  CardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import GBAsyncOperation

enum TangemKitResult<Value> {
    case success(Value)
    case failure(Error)
}

class BaseCardBalanceOperation: GBAsyncOperation {

    var card: CardViewModel
    var completion: (TangemKitResult<CardViewModel>) -> Void

    let operationQueue = OperationQueue()

    init(card: CardViewModel, completion: @escaping (TangemKitResult<CardViewModel>) -> Void) {
        self.card = card
        self.completion = completion

        operationQueue.maxConcurrentOperationCount = 1
    }

    override func main() {
//        SKIP coin market cap for now
//        loadMarketCapInfo()
        
        handleMarketInfoLoaded(priceUSD: 0.0)
    }

    func loadMarketCapInfo() {
        let coinMarketOperation = CoinMarketOperation(network: CoinMarketNetwork.btc) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleMarketInfoLoaded(priceUSD: value)
            case .failure(let error):
                self?.failOperationWith(error: String(describing: error))
            }

        }
        operationQueue.addOperation(coinMarketOperation)
    }

    func handleMarketInfoLoaded(priceUSD: Double) {
        fatalError("Override this method")
    }

    override func cancel() {
        super.cancel()
        operationQueue.cancelAllOperations()
    }

    internal func completeOperation() {
        guard !isCancelled else {
            return
        }

        completion(.success(card))
        finish()
    }

    internal func failOperationWith(error: Error) {
        guard !isCancelled else {
            return
        }

        completion(.failure(error))
        finish()
    }

}
