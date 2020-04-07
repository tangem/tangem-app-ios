//
//  RippleNetworkReserveOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import SwiftyJSON
import GBAsyncOperation

class RippleNetworkReserveOperation: GBAsyncOperation {

    private struct Constants {
        static let mainNetURL = "https://s1.ripple.com:51234"
    }

    var completion: (TangemObjectResult<String>) -> Void

    init(completion: @escaping (TangemObjectResult<String>) -> Void) {
        self.completion = completion
    }

    override func main() {
        let jsonDict = ["method": "server_state"]
        
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
                
                guard balanceInfo?["result"] != JSON.null,
                    let balanceString = balanceInfo?["result"]["state"]["validated_ledger"]["reserve_base"].stringValue,
                    let balance = UInt64(balanceString) else {
                    self.failOperationWith(error: "XRP – Missing balance object")
                    return
                }
                
                let reserveValue = NSDecimalNumber(value: balance).dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Blockchain.ripple.decimalCount))
                let rounded = (reserveValue as Decimal).rounded(blockchain: .ripple)
                self.completeOperationWith(balance: "\(rounded)")
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
