//
//  TokenNetworkBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

enum TokenNetwork: String {
    case eth = "https://mainnet.infura.io/v3/613a0b14833145968b1f656240c7d245"
    case rsk = "https://public-node.rsk.co/"
}

class TokenNetworkBalanceOperation: GBAsyncOperation {

    var card: CardViewModel
    var network: TokenNetwork
    var completion: (TangemObjectResult<String>) -> Void

    init(card: CardViewModel, network: TokenNetwork, completion: @escaping (TangemObjectResult<String>) -> Void) {
        self.card = card
        self.network = network
        self.completion = completion
    }

    override func main() {
        let address = card.address
        
        let index = address.index(address.startIndex, offsetBy: 2)
        guard let contract = card.tokenContractAddress else {
            self.failOperationWith(error: "Token card contract is empty")
            return
        }
        
        let dataValue = ["data": "0x70a08231000000000000000000000000\(address[index...])", "to": contract.replacingOccurrences(of: "\n", with: "")]

        let jsonDict = ["method": "eth_call", "params": [dataValue, "latest"], "id": 03] as [String: Any]
        
        let url = URL(string: network.rawValue)
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
                    self.failOperationWith(error: "Token – Missing check string")
                    return
                }
                
                let checkWithoutTwoFirstLetters = String(checkStr[checkStr.index(checkStr.startIndex, offsetBy: 2)...])
                
                guard let decimalNumber = arrayToDecimalNumber(checkWithoutTwoFirstLetters.asciiHexToData()!) else {
                    self.failOperationWith(error: "Token – data error")
                    return
                }
                
                guard let tokenDecimal = self.card.tokenDecimal else {
                    self.failOperationWith(error: "Card TokenDecimal is nil")
                    return
                }
                
                let normalisedValue = decimalNumber.dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: Int16(tokenDecimal)))
                
                self.completeOperationWith(balance: normalisedValue.stringValue)
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
