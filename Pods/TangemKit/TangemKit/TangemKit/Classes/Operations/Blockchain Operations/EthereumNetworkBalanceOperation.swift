//
//  EthereumNetworkBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import SwiftyJSON
import GBAsyncOperation

class EthereumNetworkBalanceOperation: GBAsyncOperation {

    private struct Constants {
        static let mainNetURL = "https://mainnet.infura.io/v3/613a0b14833145968b1f656240c7d245"
    }

    var address: String
    var completion: (TangemObjectResult<String>) -> Void

    init(address: String, completion: @escaping (TangemObjectResult<String>) -> Void) {
        self.address = address
        self.completion = completion
    }

    override func main() {
        let jsonDict = ["jsonrpc": "2.0", "method": "eth_getBalance", "params": [address, "latest"], "id": 03] as [String: Any] 
        
        let url = URL(string: Constants.mainNetURL)
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
        } catch {
            self.failOperationWith(error: String(describing: error))
        }
        
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                let balanceInfo = try? JSON(data: data)
                
                guard balanceInfo?["result"] != JSON.null, let checkStr = balanceInfo?["result"].stringValue else {
                    self.failOperationWith(error: "ETH Main – Missing check string")
                    return
                }
    
                let checkWithoutTwoFirstLetters = String(checkStr[checkStr.index(checkStr.startIndex, offsetBy: 2)...])
                
                let checkArray = checkWithoutTwoFirstLetters.asciiHexToData()
                guard let checkArrayUInt8 = checkArray, let checkInt64 = arrayToUInt64(checkArrayUInt8) else {
                    return
                }
                
                let walletValue = NSDecimalNumber(value: checkInt64).dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Blockchain.ethereum.decimalCount))
                
                self.completeOperationWith(balance: walletValue.stringValue)
            case .failure(let error):
                self.failOperationWith(error: String(describing: error))
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
