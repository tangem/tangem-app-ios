//
//  CardanoSendTransactionOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

public protocol BlockchainTxOperation: GBAsyncOperation {
    var completion: ((TangemObjectResult<Bool>) -> Void)? {get set}
}

class CardanoSendTransactionOperation: GBAsyncOperation {
    
    private struct Constants {
        static let mainNetURL = "/api/v2/txs/signed"
    }
    
    var httpBody: Data?
    var completion: ((TangemObjectResult<Bool>) -> Void)?
    var retryCount = 1
    
    init(bytes: [UInt8]) {
        super.init()
        
        do {
          //  print("Sending Cardano transaction bytes: \(bytes.hexDescription()) ")
            httpBody = try JSONSerialization.data(withJSONObject: ["signedTx" : Data(bytes: bytes).base64EncodedString()], options: [])
        } catch (let error) {
            self.failOperationWith(error: error)
        }
    }
    
    override func main() {
        let url = URL(string: CardanoBackend.current.rawValue + Constants.mainNetURL)
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = httpBody
        
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                if let responseString = String(data: data, encoding: .utf8),
                !responseString.isEmpty {
                     self.completeOperationWith(success: true)
                } else {
                     self.failOperationWith(error: "Empty response")
                }                
            case .failure(let error):
                self.handleError(error)
            }
        }
        
        task.resume()
    }
    
    func completeOperationWith(success: Bool) {
        guard !isCancelled else {
            return
        }
        
        completion?(.success(success))
        finish()
    }
    
    func failOperationWith(error: Error) {
        guard !isCancelled else {
            return
        }
        
        completion?(.failure(error))
        cancel()
    }
}


extension CardanoSendTransactionOperation: BlockchainTxOperation {
    
}

extension CardanoSendTransactionOperation: CardanoBackendHandler {
    
}
