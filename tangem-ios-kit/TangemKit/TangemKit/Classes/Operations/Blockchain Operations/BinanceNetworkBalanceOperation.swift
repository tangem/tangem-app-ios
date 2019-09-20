//
//  BinanceNetworkBalanceOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import SwiftyJSON
import GBAsyncOperation

class BinanceNetworkBalanceOperation: GBAsyncOperation {
    
    private struct Constants {
        static let mainNetURL = "https://dex.binance.org/api/v1/account/"
        static let testNetURL = "https://testnet-dex.binance.org/api/v1/account/"
    }
    
    var address: String
    var isTestNet: Bool
    var completion: (TangemObjectResult<String>) -> Void
    
    init(address: String, isTestNet: Bool = false, completion: @escaping (TangemObjectResult<String>) -> Void) {
        self.address = address
        self.isTestNet = isTestNet
        self.completion = completion
    }
    
    override func main() {
        let urlString = isTestNet ? Constants.testNetURL : Constants.mainNetURL 
        let url = URL(string: urlString + address)
        let urlRequest = URLRequest(url: url!)
        
        let task = TangemAPIClient.dataDask(request: urlRequest) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let data):
                do {
                    let balanceInfo = try JSON(data: data)
                    let balances = balanceInfo["balances"].array 
                    let bnbBalance = balances?.first(where: { $0["symbol"].stringValue == "BNB" })
                    guard let balanceString = bnbBalance?["free"].stringValue else {
                        self.failOperationWith(error: "No balance data")
                        assertionFailure()
                        return
                    }
                    
                    let walletValue = NSDecimalNumber(string: balanceString)
                    
                    self.completeOperationWith(balance: walletValue.stringValue)
                } catch {
                    self.failOperationWith(error: error)
                }
                
            case .failure(let error):
                self.failOperationWith(error: error)
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
