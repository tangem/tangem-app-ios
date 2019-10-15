//
//  CardanoUnspentOutputsOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

class CardanoUnspentOutputsOperation: GBAsyncOperation {
    
    private struct Constants {
        static let mainNetURL = "/api/bulk/addresses/utxo"
    }
    
    var address: String
    var completion: (TangemObjectResult<[CardanoUnspentOutput]>) -> Void
    var retryCount = 1
    
    init(address: String, completion: @escaping (TangemObjectResult<[CardanoUnspentOutput]>) -> Void) {
        self.address = address
        self.completion = completion
    }
    
    override func main() {
        let url = URL(string: CardanoBackend.current.rawValue + Constants.mainNetURL)
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = "[\"\(address)\"]".data(using: .utf8)
        urlRequest.addValue("utf-8", forHTTPHeaderField: "charset")
        
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                do {
                    let unspentOutputInfo = try JSON(data: data)
                    let unspentOutputsJson = unspentOutputInfo["Right"].arrayValue
                    let unspentOutputs = unspentOutputsJson.map({ (json) -> CardanoUnspentOutput in
                        let output = CardanoUnspentOutput(id: json["cuId"].stringValue, index: json["cuOutIndex"].intValue)
                        return output
                    })
                    
                    self.completeOperationWith(unspentOutputIds: unspentOutputs)
                } catch {
                    self.failOperationWith(error: error)
                }
                
            case .failure(let error):
                self.handleError(error)
            }
        }
        
        task.resume()
    }
    
    func completeOperationWith(unspentOutputIds: [CardanoUnspentOutput]) {
        guard !isCancelled else {
            return
        }
        
        completion(.success(unspentOutputIds))
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

extension CardanoUnspentOutputsOperation: CardanoBackendHandler {
    
}
