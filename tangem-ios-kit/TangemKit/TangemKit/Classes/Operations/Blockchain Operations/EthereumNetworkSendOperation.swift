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

public class EthereumNetworkSendOperation: GBAsyncOperation {
    
    private struct Constants {
        static let mainNetURL = "https://mainnet.infura.io/v3/613a0b14833145968b1f656240c7d245"
    }
    
    var tx: String
    var completion: (TangemObjectResult<String>) -> Void
    
    public init(tx: String, completion: @escaping (TangemObjectResult<String>) -> Void) {
        self.tx = tx
        self.completion = completion
    }
    
    override public func main() {
        let jsonDict = ["jsonrpc": "2.0", "method": "eth_sendRawTransaction", "params": [tx], "id": 67] as [String: Any]
        
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
                let txHashInfo = try? JSON(data: data)
                
                guard let txHashString = txHashInfo?["result"].stringValue,
                    txHashString.count > 0 else {
                        self.failOperationWith(error: "Zero response")
                        return
                }
                
                self.completeOperationWith(tx: txHashString)
            case .failure(let error):
                self.failOperationWith(error: String(describing: error))
            }
        }
        
        task.resume()
    }
    
    func completeOperationWith(tx: String) {
        guard !isCancelled else {
            return
        }
        
        completion(.success(tx))
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
