//
//  TokenNetworkBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class TokenNetworkBalanceOperation: AsynchronousOperation {
    
    private struct Constants {
        static let mainNetURL = "https://blockchain.info/balance?active="
        static let testNetURL = "https://testnet.blockchain.info/balance?active="
    }
    
    var address: String
    var contract: String
    var completion: (Result<NSDecimalNumber>) -> Void
    
    init(address: String, contract: String, completion: @escaping (Result<NSDecimalNumber>) -> Void) {
        self.address = address
        self.contract = contract
        self.completion = completion
    }
    
    override func main() {
        let index = address.index(address.startIndex, offsetBy: 2)
        let dataValue = ["data": "0x70a08231000000000000000000000000\(address[index...])", "to": contract.replacingOccurrences(of: "\n", with: "")]
        
        let jsonDict = ["method": "eth_call", "params": [dataValue, "latest"], "id": 03] as [String : Any]
        
        Alamofire.request("https://mainnet.infura.io", method: .post, parameters: jsonDict, encoding: JSONEncoding.default).responseJSON { response in
            switch response.result {
            case .success(let value):
                let balanceInfo = JSON(value)
                
                guard balanceInfo["result"] != JSON.null else {
                    self.failOperationWith(error: "Token – Missing check string")
                    return
                }
                
                let checkStr = balanceInfo["result"].stringValue
                let checkWithoutTwoFirstLetters = String(checkStr[checkStr.index(checkStr.startIndex, offsetBy: 2)...])
                
                guard let decimalNumber = arrayToDecimalNumber(checkWithoutTwoFirstLetters.asciiHexToData()!) else {
                    self.failOperationWith(error: "Token – data error")
                    return
                }
                
                self.completeOperationWith(balance: decimalNumber)
            case.failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }

    }
    
    func completeOperationWith(balance: NSDecimalNumber) {
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
