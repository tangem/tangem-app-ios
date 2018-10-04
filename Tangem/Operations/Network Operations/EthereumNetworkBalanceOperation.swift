//
//  EthereumNetworkBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class EthereumNetworkBalanceOperation: AsynchronousOperation {
    
    private struct Constants {
        static let mainNetURL = "https://mainnet.infura.io"
        static let testNetURL = "https://rinkeby.infura.io"
    }
    
    var address: String
    var isTestNet: Bool
    var completion: (Result<UInt64>) -> Void
    
    init(address: String, isTestNet: Bool = false, completion: @escaping (Result<UInt64>) -> Void) {
        self.address = address
        self.isTestNet = isTestNet
        self.completion = completion
    }
    
    override func main() {
        let jsonDict = ["jsonrpc":  "2.0", "method": "eth_getBalance", "params": [address, "latest"], "id": 03] as [String : Any]
        let url = isTestNet ? Constants.testNetURL : Constants.mainNetURL
        
        Alamofire.request(url, method: .post, parameters: jsonDict, encoding: JSONEncoding.default).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let balanceInfo = JSON(value)
                
                guard balanceInfo["result"] != JSON.null else {
                    self.failOperationWith(error: "ETH Main – Missing check string")
                    return
                }
                
                let checkStr = balanceInfo["result"].stringValue
                let checkWithoutTwoFirstLetters = String(checkStr[checkStr.index(checkStr.startIndex,offsetBy: 2)...])
                
                let checkArray = checkWithoutTwoFirstLetters.asciiHexToData()
                guard let checkArrayUInt8 = checkArray, let checkInt64 = arrayToUInt64(checkArrayUInt8) else {
                    return
                }
                
                self.completeOperationWith(balance: checkInt64)
            case.failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }
    }
    
    func completeOperationWith(balance: UInt64) {
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
