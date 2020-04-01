//
//  EthereumNetworkTxCountOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

class EthereumNetworkTxCountOperation: GBAsyncOperation {
    var address: String
    var completion: (TangemObjectResult<Int>) -> Void
    var networkUrl: String
    
    init(address: String, networkUrl: String, completion: @escaping (TangemObjectResult<Int>) -> Void) {
        self.address = address
        self.completion = completion
        self.networkUrl = networkUrl
    }
    
    override func main() {
        let jsonDict = ["jsonrpc": "2.0", "method": "eth_getTransactionCount", "params": [address, "latest"], "id": 67] as [String: Any]
        
        let url = URL(string: networkUrl)
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
                
                guard let countString = balanceInfo?["result"].stringValue,
                countString.count >= 2 else {
                    self.failOperationWith(error: "ETH Main – Missing check string")
                    return
                }
                
                let trimmed = String(countString[countString.index(countString.startIndex, offsetBy: 2)...])
                
                guard let count = Int(trimmed, radix: 16) else {
                    self.failOperationWith(error: "ETH Main – Missing check string")
                    return
                }
            
                
                self.completeOperationWith(balance: count)
                case .failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }
        
        task.resume()
    }
    
    func completeOperationWith(balance: Int) {
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
