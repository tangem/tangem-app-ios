//
//  BitcoinNetworkBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

class BitcoinNetworkBalanceOperation: GBAsyncOperation {

    private struct Constants {
        static let mainNetURL = "https://blockchain.info/balance?active="
        static let testNetURL = "https://testnet.blockchain.info/balance?active="
    }

    var address: String
    var completion: (TangemObjectResult<String>) -> Void

    init(address: String, completion: @escaping (TangemObjectResult<String>) -> Void) {
        self.address = address
        self.completion = completion
    }

    override func main() {
        let url = URL(string: Constants.mainNetURL + address)
        let urlRequest = URLRequest(url: url!)
        
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                do {
                    let balanceInfo = try JSON(data: data)
                    let satoshi = balanceInfo[self.address]["final_balance"].doubleValue
                    
                    let walletValue = NSDecimalNumber(value: satoshi).dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Blockchain.bitcoin.decimalCount))
                    
                    self.completeOperationWith(balance: walletValue.stringValue)
                } catch {
                    self.failOperationWith(error: error)
                }
                
            case .failure(let error):
                self.failOperationWith(error: error)
            }
        }
        
        task.resume()
    }

    func completeOperationWith(balance: String) {
        guard !isCancelled else {
            return
        }

        completion(.success(balance))
        finish()
    }

    func failOperationWith(error: Error) {
        guard !isCancelled else {
            return
        }

        completion(.failure(error))
        finish()
    }
}
