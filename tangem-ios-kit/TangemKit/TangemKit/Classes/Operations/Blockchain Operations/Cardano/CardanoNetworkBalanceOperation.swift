//
//  CardanoNetworkBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

struct CardanoBalanceResponse {
    
    let balance: String
    let transactionList: [String]
    
}

class CardanoNetworkBalanceOperation: GBAsyncOperation {

    private struct Constants {
        static let mainNetURL = "/api/addresses/summary/"
    }

    var address: String
    var completion: (TangemObjectResult<CardanoBalanceResponse>) -> Void
    var retryCount = 1
    
    init(address: String, completion: @escaping (TangemObjectResult<CardanoBalanceResponse>) -> Void) {
        self.address = address
        self.completion = completion
    }

    override func main() {
        let url = URL(string: CardanoBackend.current.rawValue + Constants.mainNetURL + address)
        let urlRequest = URLRequest(url: url!)
        
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                do {
                    let balanceInfo = try JSON(data: data)
                    guard let balanceString = balanceInfo["Right"]["caBalance"]["getCoin"].string,
                       let balance = Double(balanceString) else {
                        self.failOperationWith(error: balanceInfo["Left"].stringValue)
                        return
                    }
                    
                    let walletValue = NSDecimalNumber(value: balance).dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Blockchain.cardano.decimalCount))
                    
                    var transactionList = [String]()
                    if let transactionListJSON = balanceInfo["Right"]["caTxList"].array {
                        transactionList = transactionListJSON.map({ return $0["ctbId"].stringValue })
                    }
                    
                    let response = CardanoBalanceResponse(balance: walletValue.stringValue, transactionList: transactionList)
                        
                    self.completeOperationWith(response: response)
                } catch {
                    self.failOperationWith(error: error)
                }
                
            case .failure(let error):
                self.handleError(error)
            }
        }
        
        task.resume()
    }
    func completeOperationWith(response: CardanoBalanceResponse) {
        guard !isCancelled else {
            return
        }

        completion(.success(response))
        finish()
    }

    func failOperationWith(error: Error) {
        guard !isCancelled else {
            return
        }

        completion(.failure(error))
        cancel()
    }
}

extension CardanoNetworkBalanceOperation: CardanoBackendHandler {
    
}
