//
//  BitcoinNetworkBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class BitcoinNetworkBalanceOperation: AsynchronousOperation {
    
    private struct Constants {
        static let mainNetURL = "https://blockchain.info/balance?active="
        static let testNetURL = "https://testnet.blockchain.info/balance?active="
    }
    
    var address: String
    var isTestNet: Bool
    var completion: (Result<Double>) -> Void
    
    init(address: String, isTestNet: Bool = false, completion: @escaping (Result<Double>) -> Void) {
        self.address = address
        self.isTestNet = isTestNet
        self.completion = completion
    }
    
    override func main() {
        let url = isTestNet ? Constants.testNetURL : Constants.mainNetURL
        Alamofire.request(url + address, method: .get).responseJSON { response in
            switch response.result {
            case .success(let value):
                
                let balanceInfo = JSON(value)
                let satoshi = balanceInfo[self.address]["final_balance"].doubleValue
                
                self.completeOperationWith(balance: satoshi)
                
            case.failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }
    }
    
    func completeOperationWith(balance: Double) {
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
